#!/bin/bash

set -eu
DATE=$(date +%F)
NFX_CONFIG=./nextflow.config
#Options: PBS_apptainer, local_apptainer, PBS_singularity,local_singularity
NFX_PROFILE='PBS_apptainer'
#Options: star_index or rnaseq_count or sra_fastqs
NFX_ENTRY='rnaseq_count'
#The output prefix on filenames for reports/logs
REPORT=${1:-"pipeline_report"}

# Load the modules
# TO DO: make the module version a variable that the user can change eg SINGULARITY="singularity/3.9.9"; module load $SINGULARITY
if [[ $NFX_PROFILE =~ "singularity" ]]
then
    module load singularity
elif [[ $NFX_PROFILE =~ "apptainer" ]]
then
    module load apptainer
fi

# Nextflow run to execute the workflow
# TO DO: --singularity_module $SINGULARITY #the in nextflow.config could access this as params.SINGULARITY
#https://unix.stackexchange.com/questions/351901/how-can-i-get-the-positional-parameters-starting-from-two-or-more-generally
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
