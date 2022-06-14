process RSEQC_SPLITBAM {
    tag "$meta.id"
    label 'RSEQC'

    conda (params.enable_conda ? "bioconda::rseqc=4.0.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/rseqc:4.0.0--py39hbf8eff0_2':
        'quay.io/biocontainers/rseqc:4.0.0--py38h4a8c8d9_1' }"

    input:
    tuple val(meta), path(bam), path(bai)
    path gene_list

    output:
    tuple val(meta), path("*in.bam"), emit: splitbam
    path "*_rRNA_stats.out"       , emit: rRNA
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    split_bam.py \\
        -i $bam \\
        -r $gene_list \\
        -o $prefix > ${prefix}_rRNA_stats.out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rseqc: \$(echo \$(split_bam.py --version 2>&1) | sed 's/^.*split_bam.py //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
