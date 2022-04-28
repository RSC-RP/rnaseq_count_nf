nextflow.enable.dsl = 2

//global params
params.sample_sheet = "test_data/sample_sheet.txt"
params.enable_conda = false

//fastq specific params
params.outdir = "./fastqc"
params.publish_dir_mode = "copy" //not working - will need to troubleshoot

//star specific params
params.index = "~/Downloads/refs/STAR/human_v38/STAR_2.7/"
params.gtf = "~/Downloads/refs/STAR/human_v38/STAR_2.7/genes.gtf"


include { FASTQC } from './modules/nf-core/modules/fastqc/main'
include { STAR_ALIGN } from './modules/nf-core/modules/star/align'
include { TEST } from './modules/nf-core/custom/test_module.nf'

/*
// Example Input based off the github tests
input = [ [ "id":"Day0.Naive_L1Pf7", "single_end":false], //meta map
          [ file("test_data/Day0.Naive_L1Pf7_R1.fastq.gz", checkIfExists: true), 
            file("test_data/Day0.Naive_L1Pf7_R2.fastq.gz", checkIfExists: true) ]
        ]
*/

meta_ch = Channel.fromPath(file(params.sample_sheet, checkIfExists: true))
    .splitCsv(header: true, sep: '\t')
    .map { meta -> [ [ "id":meta["id"], "single_end":meta["single_end"].toBoolean() ], //meta
                     [ file(meta["r1"], checkIfExists: true), file(meta["r2"], checkIfExists: true) ] //reads
                   ]}
//meta_ch.view()

//Print statements for some basic information on process execution. 
println "Project : $workflow.projectDir"
println "Cmd line: $workflow.commandLine"
println "Container Engine: $workflow.containerEngine"
println "Containers Used: $workflow.container"


//run the workflow 
workflow rnaseq_count {
   // QC on the sequenced reads
   FASTQC(meta_ch)
   //align to genome 
   STAR_ALIGN(meta_ch,)
}

//End with a message to print to standard out on workflow completion. 
workflow.onComplete {
    println "Pipeline completed at: $workflow.complete"
    println "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
}

