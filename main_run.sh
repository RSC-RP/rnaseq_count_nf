#!/bin/bash

set -eu
DATE=$(date +%F)
NFX_CONFIG=./nextflow.config
#Options: PBS_singularity,local_singularity
NFX_PROFILE='PBS_singularity'
#Options:  rnaseq_count, prep_genome, or sra_download
NFX_ENTRY='sra_download'
#The output prefix on filenames for reports/logs
REPORT=${1:-"pipeline_report"}

# Load the modules
# TO DO: make the module version a variable that the user can change eg SINGULARITY="singularity/3.9.9"; module load $SINGULARITY
if [[ $NFX_PROFILE =~ "singularity" ]]
then
    module load singularity
fi

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
