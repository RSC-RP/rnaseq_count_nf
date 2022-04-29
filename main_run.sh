#!/bin/bash

set -e
DATE=$(date +%F)
NFX_CONFIG=./nextflow.config


nextflow -c ${NFX_CONFIG} run main.nf \
    -entry rnaseq_count \
    -with-report testing_${DATE}_local.html \
    -cache TRUE \
    -resume
