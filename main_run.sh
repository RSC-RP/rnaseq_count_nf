#!/bin/bash

set -e
DATE=$(date +%F)
NFX_CONFIG=./nextflow.config
NFX_PROFILE="cybertron_singularity"
REPORT="cybertron_singularity_interactive"

# Load the modules 
module load singularity/3.9.9
#export PATH=/depot/apps/singularity-ce/3.9.9/bin/:$PATH

# Nextflow run to execute the workflow 
nextflow -c ${NFX_CONFIG} -log ${REPORT}_nextflow.log run main.nf \
    -entry rnaseq_count \
    -profile ${NFX_PROFILE} \
    -with-report ${REPORT}_${DATE}.html \
    -with-dag ${REPORT}_${DATE}_dag.pdf \
    -cache TRUE \
    -resume
