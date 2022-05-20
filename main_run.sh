#!/bin/bash

set -eu
DATE=$(date +%F)
NFX_CONFIG=./nextflow.config
#Options: local_singularity, PBS_singularity, and local_docker
NFX_PROFILE='PBS_singularity'
#Options: star_index or rnaseq_count
NFX_ENTRY='rnaseq_count'
#The output prefix on filenames for reports/logs
REPORT="kappe_s_quant_with_rRNA_QC"

# Load the modules 
module load singularity/3.9.9

# Nextflow run to execute the workflow 
PREFIX="${REPORT}_${DATE}"
nextflow -c ${NFX_CONFIG} \
    -log reports/${PREFIX}_nextflow.log \
    run main.nf \
    -entry ${NFX_ENTRY} \
    -profile ${NFX_PROFILE} \
    -with-report reports/${PREFIX}.html \
    -with-dag dag/${PREFIX}_dag.pdf \
    -cache TRUE \
    -resume
