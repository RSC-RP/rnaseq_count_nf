nextflow.enable.dsl = 2

//Genome and input files prep
include { genome_refs } from './subworkflows/local/genome_refs.nf'
include { sra_fastqs } from './subworkflows/local/sra_fastqs.nf'

//QC modules
include { FASTQC } from './modules/nf-core/fastqc/main.nf'
include { MULTIQC } from './modules/nf-core/multiqc/main.nf'
include { RSEQC_SPLITBAM } from './modules/local/rseqc/splitbam.nf'
include { RSEQC_READDISTRIBUTION } from './modules/nf-core/rseqc/readdistribution/main.nf'
include { RSEQC_TIN } from './modules/nf-core/rseqc/tin/main.nf'

// Alignment and quantification modules
include { TRIMGALORE } from './modules/nf-core/trimgalore/main.nf'
include { PICARD_MARKDUPLICATES } from './modules/nf-core/picard/markduplicates/main'
include { STAR_ALIGN } from './modules/nf-core/star/align/main.nf'
include { SAMTOOLS_INDEX } from './modules/nf-core/samtools/index/main.nf'

//Sample manifest (params.sample_sheet) validation step to ensure appropriate formatting. 
//See bin/check_samplesheet.py from NF-CORE 

//Define stdout message for the command line use
idx_or_fasta = (params.build_index ? params.fasta : params.index)
log.info """\
         R N A S E Q -  P I P E L I N E
         ===================================
         Project           : $workflow.projectDir
         Project workDir   : $workflow.workDir
         Project outdir    : ${params.outdir}
         Container Engine  : $workflow.containerEngine
         Genome            : ${idx_or_fasta}
         Samples           : ${params.sample_sheet}
         """
         .stripIndent()

//run the workflow for star-aligner to generate counts plus perform QC
workflow rnaseq_count {

    //Reformat and stage the genome files for STAR and RSEQC
    def fasta_file = params.fasta
    def gtf_file = params.gtf
    def rRNA_file = params.rRNA_transcripts
    genome_refs(fasta_file, gtf_file, rRNA_file)

    if ( params.download_sra_fqs ){
        //Download the fastqs directly from the SRA 
        sra_fastqs()
        sra_fastqs.out.reads
            .set { fastq_ch }
    }else{
     //Create the input channel which contains the sample id, whether its single-end, and the file paths for the fastqs. 
     Channel.fromPath(file(params.sample_sheet, checkIfExists: true))
        .splitCsv(header: true, sep: ',',  skip: 4)
        .map { meta -> 
            if ( meta["single_end"].toBoolean() ){
                //single end reads have only 1 fastq file
                [ [ "id":meta["id"], "single_end":meta["single_end"].toBoolean() ], //meta
                  [ file(meta["r1"], checkIfExists: true) ] //reads
                ]
            } else {
                //paired end reads have 2 fastq files 
                [ [ "id":meta["id"], "single_end":meta["single_end"].toBoolean() ], //meta
                  [ file(meta["r1"], checkIfExists: true), file(meta["r2"], checkIfExists: true) ] //reads
                ]
            }
        }
        .set { fastq_ch }
    }

    // QC on the sequenced reads
    FASTQC(fastq_ch)
    if ( params.trim ) {
        //Adapter and Quality trimming of the fastq files 
        TRIMGALORE(fastq_ch)
        TRIMGALORE.out.log
            .set { trim_report }
        TRIMGALORE.out.reads
            .set { fastq_ch }
    }else{
        Channel.empty()
            .set { trim_report }
    }

    //
    // Alignment and Quantification
    //
    //align reads to genome 
    STAR_ALIGN(fastq_ch, 
              genome_refs.out.index, 
              genome_refs.out.gtf,
              params.star_ignore_sjdbgtf, 
              params.seq_platform,
              params.seq_center)
    //Samtools index the sorted BAM file
    SAMTOOLS_INDEX(STAR_ALIGN.out.bam)

    //
    // QC 
    //
    // Mark duplicates 
    PICARD_MARKDUPLICATES(STAR_ALIGN.out.bam, genome_refs.out.fasta, genome_refs.out.fai)
    // RSEQC on the aligned reads 
    STAR_ALIGN.out.bam
        .cross(SAMTOOLS_INDEX.out.bai) { it -> it[0].id }
        .map { meta -> [ meta[0][0], meta[0][1], meta[1][1] ] }
        .set { rseqc_ch }
    RSEQC_SPLITBAM(rseqc_ch, genome_refs.out.rRNA_bed)
    RSEQC_READDISTRIBUTION(rseqc_ch, genome_refs.out.ref_gene_model)
    RSEQC_TIN(rseqc_ch, genome_refs.out.ref_gene_model)

    //
    //
    // MultiQC
    //
    sample_sheet = file(params.sample_sheet)
    if (params.multiqc_config){
        Channel.fromPath(file(params.multiqc_config, checkIfExists: true))
            .set { multiqc_config }
    } else {
        Channel.of([])
            .set { multiqc_config }
    }
    if (params.extra_multiqc_config){
        Channel.fromPath(file(params.extra_multiqc_config, checkIfExists: true))
            .set { extra_multiqc_config }
    } else {
        Channel.of([])
            .set { extra_multiqc_config }
    }

    FASTQC.out.fastqc
        .concat(trim_report)
        // .concat(FASTQC_TRIM.out.fastqc)
        .concat(STAR_ALIGN.out.log_final)
        .concat(STAR_ALIGN.out.read_counts)
        .concat(PICARD_MARKDUPLICATES.out.metrics)
        .concat(RSEQC_READDISTRIBUTION.out.txt)
        .concat(RSEQC_TIN.out.txt)
        .map { row -> row[1]}
        .collect()
        .set { multiqc_ch }

    //Using MultiQC for a single QC report
    MULTIQC(multiqc_ch, multiqc_config, extra_multiqc_config, sample_sheet.simpleName)
}

workflow sra_download {

    main:
    def sample_sheet = params.sample_sheet
    def user_settings = params.user_settings
    //Download the fastqs directly from the SRA 
    sra_fastqs(sample_sheet, user_settings)
    sra_fastqs.out.reads
        .set { fastq_ch }

}

workflow prep_genome {

    main:
    //Reformat and stage the genome files for STAR and RSEQC
    def fasta_file = params.fasta
    def gtf_file = params.gtf
    def rRNA_file = params.rRNA_transcripts
    genome_refs(fasta_file, gtf_file, rRNA_file)

//End with a message to print to standard out on workflow completion. 
workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

}