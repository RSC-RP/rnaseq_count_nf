include { UCSC_GTFTOGENEPRED } from '../../modules/nf-core/ucsc/gtftogenepred/main'
include { UCSC_GENEPREDTOBED } from '../../modules/local/ucsc/genepredtobed.nf'
include { RSEQC_RIBOSOMALRNA } from '../../modules/local/rseqc/ribosomalrna.nf'
include { SAMTOOLS_FAIDX } from '../../modules/nf-core/samtools/faidx/main'
include { STAR_GENOMEGENERATE } from '../../modules/nf-core/star/genomegenerate/main.nf'

//Stage the genome files for RSEQC 
workflow genome_refs {
    take: 
    fasta_file
    gtf_file
    rRNA_file 

    main:
    //Stage the genome fasta files for the index building step
    Channel.fromPath(file(fasta_file, checkIfExists: true))
        .map { fasta ->  [ ["id": "${fasta.baseName}" ] ,  fasta ] }
        .collect()
        .set{ fasta_ch }
    //Stage the gtf/gff file for STAR aligner
    Channel.fromPath(file(gtf_file, checkIfExists: true))
        .map { gtf ->  [ ["id": "${gtf.baseName}" ] ,  gtf ] }
        .collect()
        .set { gtf_ch }
    // Read in the file of rRNA transcript IDs to use for rRNA contamination fraction
    Channel.fromPath(file(rRNA_file, checkIfExists: true))
        .collect()
        .set { rRNA_transcripts }

    // initialize channel 
    ch_versions = Channel.empty()

    // Index fasta file 
    SAMTOOLS_FAIDX(fasta_ch)

    //Optionally, Run the index workflow or stage the genome index directory
    if ( params.build_index == true ) {
        STAR_GENOMEGENERATE(fasta_ch, gtf_ch)
        ch_versions = ch_versions.mix(STAR_GENOMEGENERATE.out.versions)
        STAR_GENOMEGENERATE.out.index
            .collect()
            .set { index_ch }
    } else {
        Channel.fromPath(file(params.index, checkIfExists: true))
            .collect() 
            .set { index_ch }
    }

    // convert GTF to genepred file format
    UCSC_GTFTOGENEPRED( gtf_ch )
    ch_versions = ch_versions.mix(UCSC_GTFTOGENEPRED.out.versions)

    // convert genepred to bed12 format
    UCSC_GENEPREDTOBED( UCSC_GTFTOGENEPRED.out.genepred)
    ch_versions = ch_versions.mix(UCSC_GENEPREDTOBED.out.versions)

    // subset the gene bed12 file for rRNA genes
    RSEQC_RIBOSOMALRNA(UCSC_GENEPREDTOBED.out.bed, rRNA_transcripts)

    emit:
    fasta           = fasta_ch                    // channel: [ val(meta), fasta ]
    fai             = SAMTOOLS_FAIDX.out.fai      // channel: [ val(meta), fasta ]
    gtf             = gtf_ch                      // channel: [ val(meta), gtf ]
    index           = index_ch                    // channel: [ index ]
    ref_gene_model  = UCSC_GENEPREDTOBED.out.bed  // channel: [ val(meta), [ bam ] ]
    rRNA_bed        = RSEQC_RIBOSOMALRNA.out.rRNA // channel: [ val(meta), [ rRNA_bed ] ]
    versions        = ch_versions                 // channel: [ versions.yml ]
}

