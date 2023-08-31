process UCSC_GENEPREDTOBED {
    tag "${meta.id}"
    label 'process_low'

    conda "bioconda::ucsc-genepredtobed=447"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ucsc-genepredtobed:447--h954228d_0':
        'biocontainers/ucsc-genepredtobed:447--h954228d_0' }"

    input:
    tuple val(meta), path(genepred)
    tuple val(meta2), path(tx_info)
    val rRNA_biotypes

    output:
    tuple val(meta), path("*.sort.bed")     , emit: bed
    tuple val(meta), path("*rRNA.bed")      , emit: rRNA
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '477'
    """
    genePredToBed ${genepred} ${prefix}.bed 
    sort -k1,1 -k2,2n ${prefix}.bed  > ${prefix}.sort.bed
    
    grep -E "$rRNA_biotypes" ${tx_info} | cut -f 1 > rRNA.txt
    grep -f rRNA.txt ${prefix}.sort.bed > ${prefix}.sort.rRNA.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc: $VERSION
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.sort.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc: $VERSION
    END_VERSIONS
    """
}
