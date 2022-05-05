nextflow.enable.dsl = 2

include { FASTQC } from './modules/nf-core/modules/fastqc/main.nf'
include { STAR_ALIGN } from './modules/nf-core/modules/star/align/main.nf'
include { STAR_GENOMEGENERATE } from './modules/nf-core/modules/star/genomegenerate/main.nf'

meta_ch = Channel.fromPath(file(params.sample_sheet, checkIfExists: true))
    .splitCsv(header: true, sep: '\t')
    .map { meta -> [ [ "id":meta["id"], "single_end":meta["single_end"].toBoolean() ], //meta
                     [ file(meta["r1"], checkIfExists: true), file(meta["r2"], checkIfExists: true) ] //reads
                   ]}

//Print statements for some basic information on process execution. 
println "Project : $workflow.projectDir"
println "Project workDir: $workflow.workDir"
println "Container Engine: $workflow.containerEngine"

//run the workflow for star-aligner to generate counts
workflow rnaseq_count {
    // QC on the sequenced reads
    FASTQC(meta_ch)
    //Stage the gtf file. 
    Channel.fromPath(params.gtf)
        .ifEmpty { error  "No file found ${params.gtf_url}." }
        .set{gtf}  
    //Stage the genome index directory.
    Channel.fromPath(params.index)
        .ifEmpty { error "No directory found ${params.index}." }
        .set{index}
   //align reads to genome 
    STAR_ALIGN(meta_ch, index, gtf, 
              params.star_ignore_sjdbgtf, 
              params.seq_platform,
              params.seq_center)
}

//Generate the index file 
workflow star_index {
    //Stage the gtf file
    Channel.fromPath(params.gtf)
        .ifEmpty { error  "No file found ${params.gtf_url}" }
        .set{gtf}  
    //Stage the genome fasta files for the index building step
    Channel.fromPath(params.fasta)
        .ifEmpty { error "No files found ${params.fasta_file}." }
        .set{fasta}
    //execute the STAR genome index process
    STAR_GENOMEGENERATE(fasta, gtf)
}

//End with a message to print to standard out on workflow completion. 
workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

