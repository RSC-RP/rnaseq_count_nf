process RSEQC_RIBOSOMALRNA {
    tag "${meta.id}"
    label 'process_low'

    conda "bioconda::rseqc=5.0.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/rseqc:5.0.1--py36h91eb985_0':
        'biocontainers/rseqc:5.0.1--py36h91eb985_0' }"

    input:
    tuple val(meta), path(gene_bed)
    path rRNA_ids

    output:
    tuple val(meta), path("*.rRNA.bed")               , emit: rRNA
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    grep -f ${rRNA_ids} ${gene_bed} > ${prefix}.sort.rRNA.bed
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rseqc: NA
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """
    touch ${prefix}.sort.rRNA.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rseqc: NA
    END_VERSIONS
    """
}
