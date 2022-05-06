#!/bin/bash

set -e
DATE=$(date +%F)
NFX_CONFIG=./nextflow.config
NFX_PROFILE="PBS_singularity"
REPORT="star_index_multispecies"

# Load the modules 
module load singularity/3.9.9

# Nextflow run to execute the workflow 
nextflow -c ${NFX_CONFIG} -log reports/${REPORT}_nextflow.log run main.nf \
    -entry star_index \
    -profile ${NFX_PROFILE} \
    -with-report reports/${REPORT}_${DATE}.html \
    -with-dag dag/${REPORT}_${DATE}_dag.pdf \
    -cache TRUE \
    -resume
