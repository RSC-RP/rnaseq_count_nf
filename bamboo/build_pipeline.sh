#!/bin/bash -l

set -eou pipefail

# Set-up environment on HPC 
export RSTUDIO_PANDOC="/usr/lib/rstudio-server/bin/pandoc"
module load R/4.1.0-foss-2020b

# bamboo automation assumes these environment variables are passed in from build_pipeline.sh called by build.sh
export WORK_DIR=$WORK_DIR
export IMAGE_CACHE=$IMAGE_CACHE
cd $TEMP_DIR

# Set-up nexflow conda env
DATE=$(date +%F)
CONDA_ENV_NAME="nxf_temp"

echo "create new mamba environment"
# print out the software version information. Assumes svc account has mamba installed in default location.
VER=$(mamba --version)
echo "mamba version:" $VER
mamba env create --quiet --force -f env/nextflow.yaml --name "$CONDA_ENV_NAME"

echo "activate nextflow mamba environment"
conda activate $CONDA_ENV_NAME
mamba env list

echo "create artifact dir"
mkdir -p artifacts
OUTDIR='./artifacts'

echo "create nextflow work directory"
WORK_DIR=$WORK_DIR/$(basename $TEMP_DIR)
mkdir -p $WORK_DIR
echo $WORK_DIR

echo "create artifacts"
# run the pipeline using the default parameters
export REPORT1="$OUTDIR/paired_end_test"
# bash ./bamboo/bamboo_main_run.sh $(basename $REPORT1) \
#     --outdir "$REPORT1" \
#     -work-dir "$WORK_DIR"
# render the markdown file
# since `workflow_run.Rmd` is in a subdirectory, must make REPORT1 a relative path pointing up one directory (eg ../artifacts/paired_end_test)
export REPORT1_RMD_PATH=".$OUTDIR/paired_end_test"
# Rscript -e "rmarkdown::render('workflow_docs/workflow_run.Rmd', encoding = 'UTF-8', params = list(outdir = Sys.getenv('REPORT1_RMD_PATH')), output_format = 'all')"
# cp -r workflow_docs $REPORT1

# run the pipeline using the default parameters and building the bowtie indexes
# REPORT2="single_end_test"
# bash ./bamboo/bamboo_main_run.sh $REPORT2 --outdir "$OUTDIR/$REPORT2" --build_index 'true' --build_spike_index 'true'
# Rscript -e "rmarkdown::render('workflow_docs/workflow_run.Rmd', encoding = 'UTF-8', params = list(outdir = Sys.getenv('REPORT2')), output_format = 'all')"
# cp -r workflow_docs $REPORT2

# run with different executors 

# run different entry points

# Deactivate and delete the environment 
echo "Deactivate and delete the environment"
conda deactivate
mamba env remove --name $CONDA_ENV_NAME --yes