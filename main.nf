nextflow.enable.dsl = 2

//Genome prep
include { genome_refs } from './subworkflows/local/genome_refs.nf'

//QC modules
include { FASTQC } from './modules/nf-core/fastqc/main.nf'
include { MULTIQC } from './modules/nf-core/multiqc/main.nf'
include { RSEQC_SPLITBAM } from './modules/local/rseqc/splitbam.nf'
include { RSEQC_READDISTRIBUTION } from './modules/nf-core/rseqc/readdistribution/main.nf'
include { RSEQC_TIN } from './modules/nf-core/rseqc/tin/main.nf'

// Alignment and quantification modules
include { TRIMGALORE } from './modules/nf-core/trimgalore/main.nf'
include { STAR_ALIGN } from './modules/nf-core/star/align/main.nf'
include { STAR_GENOMEGENERATE } from './modules/nf-core/star/genomegenerate/main.nf'
include { SAMTOOLS_INDEX } from './modules/nf-core/samtools/index/main.nf'
include { SRATOOLS_FASTERQDUMP } from './modules/nf-core/sratools/fasterqdump/main.nf'

//Sample manifest (params.sample_sheet) validation step to ensure appropriate formatting. 
//See bin/check_samplesheet.py from NF-CORE 

//Define stdout message for the command line use
idx_or_fasta = (params.build_index ? params.fasta : params.index)
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

//run the workflow for star-aligner to generate counts plus perform QC
workflow rnaseq_count {
    //Run the index workflow or stage the genome index directory
    if ( params.build_index == true ) {
        star_index()
        star_index.out.index
            .collect()
            .set { index }
    } else {
        Channel.fromPath(file(params.index, checkIfExists: true))
            .collect() 
            .set { index }
    }

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
    //Stage the gtf/gff file for STAR aligner
    Channel.fromPath(file(params.gtf, checkIfExists: true))
        .map { gtf ->  [ ["id": "${gtf.baseName}" ] ,  gtf ] }
        .collect() //collect converts this to a value channel and used multiple times
        .set { gtf_ch }

    Channel.of(params.rRNA_biotypes)
        // .splitCsv()
        // .map { row -> [row] }
        // .reduce { a,b -> println "a: $a b: $b"; return [a+b] }
        .view { "results = $it" }

    Channel
        .of( 1, 2, 3, 4, 5 )
        .reduce { a, b -> println "a: $a b: $b"; return a+b }
        .view { "result = $it" }

    //Stage the genome files for RSEQC 
    // genome_refs(gtf_ch, rRNA_biotypes)
    // Channel.fromPath(file(params.gene_list, checkIfExists: true))
    //     .collect()
    //     .set { gene_list }
    // Channel.fromPath(file(params.ref_gene_model, checkIfExists: true))
    //     .collect()
    //     .set { ref_gene_model }
    // // QC on the sequenced reads
    // FASTQC(fastq_ch)
    // if ( params.trim ) {
    //     //Adapter and Quality trimming of the fastq files 
    //     TRIMGALORE(fastq_ch)
    //     TRIMGALORE.out.log
    //         .set { trim_report }
    //     TRIMGALORE.out.reads
    //         .set { fastq_ch }
    // }else{
    //     Channel.empty()
    //         .set { trim_report }
    // }
    // //align reads to genome 
    // STAR_ALIGN(fastq_ch, index, gtf,
    //           params.star_ignore_sjdbgtf, 
    //           params.seq_platform,
    //           params.seq_center)
    // //Samtools index the sorted BAM file
    // SAMTOOLS_INDEX(STAR_ALIGN.out.bam)
    // //RSEQC on the aligned reads 
    // STAR_ALIGN.out.bam
    //     .cross(SAMTOOLS_INDEX.out.bai) { it -> it[0].id }
    //     .map { meta -> [ meta[0][0], meta[0][1], meta[1][1] ] }
    //     .set { rseqc_ch }
    // RSEQC_SPLITBAM(rseqc_ch, gene_list)
    // RSEQC_READDISTRIBUTION(rseqc_ch, ref_gene_model)
    // RSEQC_TIN(rseqc_ch, ref_gene_model)

    // //
    // //
    // // MultiQC
    // //
    // sample_sheet = file(params.sample_sheet)
    // if (params.multiqc_config){
    //     Channel.fromPath(file(params.multiqc_config, checkIfExists: true))
    //         .set { multiqc_config }
    // } else {
    //     Channel.of([])
    //         .set { multiqc_config }
    // }
    // if (params.extra_multiqc_config){
    //     Channel.fromPath(file(params.extra_multiqc_config, checkIfExists: true))
    //         .set { extra_multiqc_config }
    // } else {
    //     Channel.of([])
    //         .set { extra_multiqc_config }
    // }

    // FASTQC.out.fastqc
    //     .concat(trim_report)
    //     // .concat(FASTQC_TRIM.out.fastqc)
    //     .concat(STAR_ALIGN.out.log_final)
    //     .concat(STAR_ALIGN.out.read_counts)
    //     // .concat(PICARD_MARKDUPLICATES.out.metrics)
    //     .concat(RSEQC_READDISTRIBUTION.out.txt)
    //     .concat(RSEQC_TIN.out.txt)
    //     .map { row -> row[1]}
    //     .collect()
    //     .set { multiqc_ch }

    // //Using MultiQC for a single QC report
    // MULTIQC(multiqc_ch, multiqc_config, extra_multiqc_config, sample_sheet.simpleName)
}

// //Generate the index file 
// workflow star_index {
//     main: 
//     //Stage the gtf file
//     Channel.fromPath(file(params.gtf, checkIfExists: true))
//         .set{ gtf }  
//     //Stage the genome fasta files for the index building step
//     Channel.fromPath(file(params.fasta, checkIfExists: true))
//         .set{ fasta }
//     //execute the STAR genome index process
//     STAR_GENOMEGENERATE(fasta, gtf)

//     emit:
//     index = STAR_GENOMEGENERATE.out.index
// }

// workflow sra_fastqs {
//     main: 
//     // stage the sample sheet
//     Channel.fromPath(file(params.sample_sheet, checkIfExists: true))
//         .splitCsv(header: true, sep: ',', skip: 2)
//         .map { meta -> [ "id":meta["id"], "single_end":meta["single_end"].toBoolean() ] } //meta
//         .set { accessions_ch }

//     // stage the NCBI sratoolkit config file
//     Channel.fromPath(file(params.user_settings, checkIfExists: true))
//         .collect()
//         .set { user_settings }
//     // Run fastq dump 
//    SRATOOLS_FASTERQDUMP(accessions_ch, user_settings)

//    emit:
//    reads = SRATOOLS_FASTERQDUMP.out.reads
// }

//End with a message to print to standard out on workflow completion. 
workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

