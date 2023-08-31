include { UCSC_GTFTOGENEPRED } from '../../modules/nf-core/ucsc/gtftogenepred/main'
include { UCSC_GENEPREDTOBED } from '../../modules/local/ucsc/genepredtobed.nf'

//Stage the genome files for RSEQC 
workflow genome_refs {

    take:
    gtf_ch // channel: [ val(meta), [ gtf ] ]
    rRNA_biotypes

    main:

    UCSC_GTFTOGENEPRED( gtf_ch )
    ch_versions = Channel.empty()
    ch_versions = ch_versions.mix(UCSC_GTFTOGENEPRED.out.versions)

    UCSC_GENEPREDTOBED( UCSC_GTFTOGENEPRED.out.genepred,
                        UCSC_GTFTOGENEPRED.out.tx_info, 
                        rRNA_biotypes )
    ch_versions = ch_versions.mix(UCSC_GENEPREDTOBED.out.versions)

    // gtf_ch.
    //     .map { meta, gtf -> gtf }
    //     .set { gtf }

    emit:
    // gtf             = gtf // [ gtf ]
    // ref_gene_model  = UCSC_GENEPREDTOBED.out.bed     // channel: [ val(meta), [ bam ] ]
    // rRNA_bed    = 
    versions    = ch_versions                    // channel: [ versions.yml ]
}

