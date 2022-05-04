#!/bin/bash

set -e
DATE=$(date +%F)
NFX_CONFIG=./nextflow.config

#Load the modules 
ml singularity/3.5.0
#export PATH=/depot/apps/singularity/3.5.0/bin/:$PATH

nextflow -c ${NFX_CONFIG} run main.nf \
    -entry rnaseq_count \
    -with-report testing_${DATE}_local.html \
    -cache TRUE \
    -resume
