#!/bin/bash

set -eu
DATE=$(date +%F)
NFX_CONFIG=./nextflow.config
NFX_PROFILE='sasquatch'
#Options:  rnaseq_count, prep_genome, or sra_download
NFX_ENTRY='rnaseq_count'
#The output prefix on filenames for reports/logs
REPORT=${1:-"pipeline_report"}
# Your association name
ASSOC='mylab'
# Working directory for temporary intermediate files
WORKDIR="/data/hps/assoc/private/$ASSOC/user/$USER/temp_rnaseq"

# Nextflow run to execute the workflow
PREFIX="${REPORT}_${DATE}"
nextflow -c ${NFX_CONFIG} \
    -log reports/${PREFIX}_nextflow.log \
    run main.nf \
    --assoc ${ASSOC} \
    -work-dir ${WORKDIR} \
    -entry ${NFX_ENTRY} \
    -profile ${NFX_PROFILE} \
    -with-report reports/${PREFIX}.html \
    -with-dag dag/${PREFIX}_dag.pdf \
    -cache TRUE \
    -resume
