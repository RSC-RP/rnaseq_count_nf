// this works with the
process TEST {

    publishDir "$params.TEST_OUT"

    container 'quay.io/biocontainers/fastqc:0.11.9--0'
    cpus 1
    memory "1 GB"

    input:
    tuple val(meta), path(reads)

    output:
    stdout

    script:
    def prefix = "${meta.id}"
    def type = "${meta.single_end}"
    """
    echo "the sample prefix is: ${prefix}"
    echo "the type of seq is: ${type}"
    echo "the first read is: ${reads[0]}"
    fastqc --help
    """
}