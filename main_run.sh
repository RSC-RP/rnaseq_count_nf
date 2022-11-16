#!/bin/bash

set -eu
DATE=$(date +%F)
NFX_CONFIG=./nextflow.config
#Options: local_singularity, PBS_singularity, and PBS_conda
NFX_PROFILE='PBS_singularity'
#Options: star_index or rnaseq_count or sra_fastqs
NFX_ENTRY='rnaseq_count'
#The output prefix on filenames for reports/logs
REPORT=${1:-"pipeline_report"}

# Load the modules
# TO DO: make the module version a variable that the user can change eg SINGULARITY="singularity/3.9.9"; module load $SINGULARITY
if [[ $NFX_PROFILE =~ "singularity" ]]
then
    module load singularity
fi

# Nextflow run to execute the workflow
# TO DO: --singularity_module $SINGULARITY #the in nextflow.config could access this as params.SINGULARITY
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
