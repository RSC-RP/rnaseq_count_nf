include { SRATOOLS_FASTERQDUMP } from '../../modules/nf-core/sratools/fasterqdump/main.nf'

workflow sra_fastqs {
    take: 
    sample_sheet 
    user_settings

    main: 
    // stage the sample sheet
    Channel.fromPath(file(sample_sheet, checkIfExists: true))
        .splitCsv(header: true, sep: ',', skip: 2)
        .map { meta -> [ "id":meta["id"], "single_end":meta["single_end"].toBoolean() ] } //meta
        .set { accessions_ch }

    // stage the NCBI sratoolkit config file
    Channel.fromPath(file(user_settings, checkIfExists: true))
        .collect()
        .set { user_settings }
    // Run fastq dump 
   SRATOOLS_FASTERQDUMP(accessions_ch, user_settings)

   emit:
   reads = SRATOOLS_FASTERQDUMP.out.reads
}