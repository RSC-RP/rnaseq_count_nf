nextflow.enable.dsl = 2

include { FASTQC } from './modules/nf-core/modules/fastqc/main.nf'
include { MULTIQC } from './modules/nf-core/modules/multiqc/main.nf'
include { RSEQC_SPLITBAM } from './modules/local/rseqc/splitbam.nf'
include { STAR_ALIGN } from './modules/nf-core/modules/star/align/main.nf'
include { STAR_GENOMEGENERATE } from './modules/nf-core/modules/star/genomegenerate/main.nf'

//Sample manifest (params.sample_sheet) validation step to ensure appropriate formatting. 
//See bin/check_samplesheet.py from NF-CORE 

//Define stdout message for the command line use
idx_or_fasta = (params.index == '' ? params.fasta : params.index)
log.info """\
         R N A S E Q -  P I P E L I N E
         ===================================
         Project           : $workflow.projectDir
         Project workDir   : $workflow.workDir
         Container Engine  : $workflow.containerEngine
         Genome            : ${idx_or_fasta}
         Samples           : ${params.sample_sheet}
         """
         .stripIndent()

//run the workflow for star-aligner to generate counts
workflow rnaseq_count {
    //Run the index workflow or stage the genome index directory
    if ( param.index == '' ) {
        star_index()
        star_index.out.index 
            .set { index }
    } else {
        Channel.fromPath(params.index)
            .ifEmpty { error "No directory found ${params.index}." }
            .collect() 
            .set { index }
    }
    //Create the input channel which contains the SAMPLE_ID, whether its single-end, and the file paths for the fastqs. 
     Channel.fromPath(file(params.sample_sheet))
        .ifEmpty { error  "No file found ${params.sample_sheet}." }
        .splitCsv(header: true, sep: '\t')
        .map { meta -> [ [ "id":meta["id"], "single_end":meta["single_end"].toBoolean() ], //meta
                        [ file(meta["r1"], checkIfExists: true), file(meta["r2"], checkIfExists: true) ] //reads
                    ]}
        .set { meta_ch }
    //Stage the gtf/gff file for STAR aligner
    Channel.fromPath(params.gtf)
        .ifEmpty { error  "No file found ${params.gtf}." }
        .collect() //collect converts this to a value channel and used multiple times
        .set { gtf }
    //Stage the genome files for RSEQC 
    Channel.fromPath(params.gene_list)
        .ifEmpty { error "No file found ${params.gene_list}" }
        .collect()
        .set { gene_list }
    Channel.fromPath(params.ref_gene_model)
        .ifEmpty { error "No file found ${params.ref_gene_model}" }
        .collect()
        .set { ref_gene_model }
    // QC on the sequenced reads
    FASTQC(meta_ch)
    //align reads to genome 
    STAR_ALIGN(meta_ch, index, gtf,
              params.star_ignore_sjdbgtf, 
              params.seq_platform,
              params.seq_center)
    //Samtools index
    //NEED TO INDEX BAM files, optionally sort? or just require STAR_ALIGN to sort bams?
    //RSEQC on the aligned reads 
    RSEQC_SPLITBAM(STAR_ALIGN.out.bam, gene_list)
    RSEQC_READDISTRIBUTION(STAR_ALIGN.out.bam, ref_gene_model)
    RSEQC_TIN(STAR_ALIGN.out.bam, ref_gene_model)
    //Combine the fastqc and star-aligner QC output into a single channel
    sample_sheet=file(params.sample_sheet)
    multiqc_ch = FASTQC.out.fastqc.collect()
        .combine(STAR_ALIGN.out.log_final.collect())
        .combine(STAR_ALIGN.out.read_counts.collect())
    //Using MultiQC for a single QC report
    MULTIQC(multiqc_ch, sample_sheet.simpleName)
}

//Generate the index file 
workflow star_index {
    main: 
    //Stage the gtf file
    Channel.fromPath(params.gtf)
        .ifEmpty { error  "No file found ${params.gtf}" }
        .set{gtf}  
    //Stage the genome fasta files for the index building step
    Channel.fromPath(params.fasta)
        .ifEmpty { error "No files found ${params.fasta}." }
        .set{fasta}
    //execute the STAR genome index process
    STAR_GENOMEGENERATE(fasta, gtf)

    emit:
    index = STAR_GENOMEGENERATE.out.index
}

//End with a message to print to standard out on workflow completion. 
workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

