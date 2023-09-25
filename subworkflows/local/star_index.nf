include { STAR_GENOMEGENERATE } from '../../modules/nf-core/star/genomegenerate/main.nf'

//Generate the index file 
workflow star_index {

    take:
    fasta
    gtf

    main: 
    gtf
        .map { meta, gft -> gtf }
        .set { gtf_ch}
    fasta
        .map { meta, fasta -> fasta }
        .set { fasta_ch }
    //execute the STAR genome index process
    STAR_GENOMEGENERATE(fasta_ch, gtf_ch)

    emit:
    index = STAR_GENOMEGENERATE.out.index
}