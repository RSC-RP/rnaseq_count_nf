nextflow.enable.dsl = 2

include { FASTQC } from './modules/nf-core/modules/fastqc/main.nf'
include { STAR_ALIGN } from './modules/nf-core/modules/star/align/main.nf'
include { STAR_ALIGN } from './modules/nf-core/modules/star/align/main.nf'

meta_ch = Channel.fromPath(file(params.sample_sheet, checkIfExists: true))
    .splitCsv(header: true, sep: '\t')
    .map { meta -> [ [ "id":meta["id"], "single_end":meta["single_end"].toBoolean() ], //meta
                     [ file(meta["r1"], checkIfExists: true), file(meta["r2"], checkIfExists: true) ] //reads
                   ]}
//meta_ch.view()

//Print statements for some basic information on process execution. 
println "Project : $workflow.projectDir"
println "Project workDir: $workflow.workDir"
println "Cmd line: $workflow.commandLine"
println "Container Engine: $workflow.containerEngine"
//println "Containers Used: $workflow.container" //not working?

//Generate the index file 
workflow star_index {
    //Stage the gtf file
    Channel.fromPath(params.gtf_file)
        .ifEmpty { error  "No file found ${params.gtf_url}" }
        .set{gtf}  
    
    //Stage the genome fasta files for the index building step
    Channel.fromPath(params.fasta_file)
        .ifEmpty { error "No files found ${params.fasta_file}." }
        .set{fasta}
    
    STAR_GENOMEGENERATE(fasta, gtf)
}

//run the workflow 
workflow rnaseq_count {
   // QC on the sequenced reads
   //FASTQC(meta_ch)
   //align to genome 
   STAR_ALIGN(meta_ch, params.index, params.gtf, 
              params.star_ignore_sjdbgtf, params.seq_platform, params.seq_center)
}

//End with a message to print to standard out on workflow completion. 
workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

