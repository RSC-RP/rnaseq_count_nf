Nextflow ‘rnaseq_count_nf’ Pipeline Run Instructions
================
Jenny L Smith
2024-02-07

- [About the Workflow](#about-the-workflow)
- [Activate the Environment on HPC](#activate-the-environment-on-hpc)
  - [1) Interactive Session](#1-interactive-session)
  - [2) Open CutandRun workflow
    folder](#2-open-cutandrun-workflow-folder)
  - [3) Activate conda environement](#3-activate-conda-environement)
- [Test the Workflow](#test-the-workflow)
  - [Edit the Config File](#edit-the-config-file)
  - [Paired-end example](#paired-end-example)
  - [Single-end example](#single-end-example)
  - [sra download example](#sra-download-example)
- [Modify the Pipeline for Your
  Data](#modify-the-pipeline-for-your-data)
  - [Define Input Files](#define-input-files)
  - [Nextflow Config](#nextflow-config)
  - [Genome References](#genome-references)
  - [Advanced Options](#advanced-options)
- [Run the workflow](#run-the-workflow)
- [Expected Outputs](#expected-outputs)
- [Share the Data](#share-the-data)
- [Cleaning up Cached Data](#cleaning-up-cached-data)
- [Session Information](#session-information)

# About the Workflow

This workflow is designed to output gene expression counts from STAR
aligner using
[`--quantmode`](https://physiology.med.cornell.edu/faculty/skrabanek/lab/angsd/lecture_notes/STARmanual.pdf).
It will also perform general QC statistics on the fastqs with
[fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) and
the alignment using [rseqc](https://rseqc.sourceforge.net/). Finally,
the QC reports are collected into a single file using
[multiQC](https://multiqc.info/).

A DAG (directed acyclic graph) of the workflow is show below:

<img src="../images/dag.png" width="4722" style="display: block; margin: auto;" />

# Activate the Environment on HPC

The directions to set-up the Nextflow workflow requirements are found in
the [README.md](../README.md). Ensure that you have followed the steps
to fork and clone the repository and created the conda nextflow
environment before starting with this document.

### 1) Interactive Session

Optional but recommended: use `tmux` on the cybertron login nodes. Name
the session nextflow and then request an interactive session, then
activate the nextflow conda environment. The project codes can be found
with `project info` command. Change the `$QUEUE` and `$NAME` variables
in the code chunk below to be accurate for your Cybertron projects.

``` bash
tmux new-session -s nextflow
project info
NAME="RSC_adhoc"
QUEUE="paidq"
qsub -I -q $QUEUE -P $(project code $NAME) -l select=1:ncpus=1:mem=8g -l walltime=8:00:00
```

### 2) Open CutandRun workflow folder

Navigate to where you place the cloned (copied) cutandrun_nf directory,
and then checkout the latest release branch.

``` bash
cd /path/to/my/rnaseq_count_nf
git fetch

# this will list all branches of the repository. Find the release branch with the latest version in red text, which means you don't yet have a local copy of that branch. 
git branch -a

# then select the latest version, for example 2.0.0. This downloads the stable version of pipeline locally. 
git checkout release/2.0.0

# Now the * indicates that you're on the release branch and its no longer red text. 
git branch
```

### 3) Activate conda environement

Activate the Nextflow conda environment.

``` bash
conda env create -f env/nextflow.yaml
conda activate nextflow
```

# Test the Workflow

## Edit the Config File

Edit the `nextflow.config` file in any text editor; the example below is
in R.

You will need to change the:

- project code (use the same one as you used above),
- the queue name to be paidq or a tier 3 queue.

Paidq will cost less than \$0.01 for testing with the workflow’s example
data provided in the directory `test_data`.

    //global parameters
    params {
        // general options
        sample_sheet                = "test_data/paired_end_sample_sheet.csv"
        download_sra_fqs            = false
        queue                       = 'paidq'
        project                     = '[PROJECT CODE]'
    <...continues...>

``` r
usethis::edit_file("../nextflow.config")
```

## Paired-end example

Determine if the workflow works on your installation of the conda
environment by running the following command.

``` bash
./main_run.sh "paired_end_test"
```

## Single-end example

To test the single-end sheet, modify the sample_sheet parameter in the
`nextflow.config` and the output directory (`outdir`).

    params {
        // general options
        sample_sheet                = "test_data/single_end_sample_sheet.csv"
        [...]
        outdir                      = "./single_end_results/"
    <...continues...>
    }

then run the command

``` bash
./main_run.sh "single_end_test"
```

## sra download example

To test the sra sample sheet - modify these the sample sheet, and set
`download_sra_fastqs` to true in the `nextflow.config` and the output
directory (`outdir`).

    params {
        // general options
        sample_sheet                = "test_data/sra_sample_sheet.csv"
        download_sra_fqs            = true
        [...]
        outdir                      = "./sra_results/"
    <...continues...>
    }

then run on the command:

``` bash
./main_run.sh "sra_test"
```

# Modify the Pipeline for Your Data

## Define Input Files

A comma delimited (csv) sample sheet is required for the input samples
to be processed. Please note, ***do not remove*** the comment lines that
begin with “\#” in the example files. The same number of comment lines
*must* be included in any input sample sheet, based on the examples
provided here.

It must have the column names (in any order):

- r1 - the filepath for the read 1 fastq in paired-end RNA-seq, or the
  single-end fastq file

- r2 - the filepath for the read 2 fastq in paired-end RNA-seq

- id - unique sample ID, no duplicates allowed in the sample sheet

- single_end - boolean \[true/false\] if the data is single-end or
  paired-end

The two examples are provided here to look at:

``` r
example_sheet <- read.csv(here::here("test_data/paired_end_sample_sheet.csv"),
    header = TRUE, comment.char = "#")
example_sheet
```

    ##   single_end                                  r1
    ## 1      false test_data/Sample_ID_001_R1.fastq.gz
    ##                                    r2            id
    ## 1 test_data/Sample_ID_001_R2.fastq.gz Sample_ID_001

If downloading the fastq files directly from the SRA, the sample sheet
only requires the `id` and the `single_end` columns.

``` r
sra_example <- read.csv(here::here("test_data/sra_sample_sheet.csv"),
    header = TRUE, comment.char = "#")

sra_example
```

    ##          id single_end
    ## 1 SRR013553       true
    ## 2 SRR013564       true

## Nextflow Config

Edit the `nextflow.config` file to include the appropriate filepaths for
the samples to be included in the pipeline, and the appropriate genome
references. The required files are listed here:

    ## //working directory for temporary/intermediate files produced in the workflow processes
    ## workDir = "$HOME/temp"
    ## 
    ## //global parameters
    ## params {
    ##     // general options
    ##     sample_sheet                = "test_data/paired_end_sample_sheet.csv"
    ##     queue                       = 'paidq'
    ##     project                     = '207f23bf-acb6-4835-8bfe-142436acb58c'
    ## 
    ##     // Input and output options
    ##     download_sra_fqs            = false
    ##     outdir                      = "./paired_end_results/"
    ##     publish_dir_mode            = 'copy'
    ## 
    ##     // STAR specific params
    ##     index                       = '/gpfs/shared_data/STAR/human_GRCh38_ensembl_v106/star'
    ##     build_index                 = false
    ##     gtf                         = '/gpfs/shared_data/STAR/human_GRCh38_ensembl_v106/Homo_sapiens.GRCh38.106.gtf' // required
    ##     fasta                       = '/gpfs/shared_data/STAR/human_GRCh38_ensembl_v106/Homo_sapiens.GRCh38.dna.primary_assembly.fa' // required
    ## <...>

## Genome References

Rseqc reference bed files are generated using the provided GTF file in
params section of the `nextflow.config` file. The ref_gene_model is
generated in BED12 format using UCSC utilities (Kent tools). This allows
the Rseqc references to match the transcript IDs used in the GTF for
STAR aligner. The pipeline does require the user to provide a list of
rRNA transcript IDs that match the transcript ID format in the provided
GTF.

The easiest way to find the rRNA transcripts is to use [Ensembl
Biomart](http://useast.ensembl.org/biomart/martview/d3ad0d42cda078c0acc2a4b2c18a9164)
or [UCSC table browser](https://genome.ucsc.edu/cgi-bin/hgTables). For
Ensembl, use a filter based on the rRNA biotypes you would like to
quantify (eg Mt_rRNA , rRNA , rRNA_pseudogene) and then select
“Transcript stable ID” as the Attribute to save to file.

In R, this could be accomplished with:

    library(biomaRt)
    species <- "Homo_sapiens"
    mart <- useEnsembl('ensembl', dataset = 'Homo_sapiens_gene_ensembl')
    biomaRt::getBM(values=c("rRNA", "rRNA_pseudogene","Mt_rRNA"),
                   filters="biotype", 
                   attributes=c("ensembl_transcript_id"), 
                   mart = mart)

An example of the gene models and rRNA bed files can be found at the
RSEQC [documentation
page](http://rseqc.sourceforge.net/#download-gene-models-update-on-12-14-2021)
and are located at `/gpfs/shared_data/rseqc` to share with the SCRI.

## Advanced Options

In the `nextflow.config`, you can define additional command line
arguments to the scientific software under [process
scope](https://www.nextflow.io/docs/latest/process.html#).

    ## // Computational resource allocation for the processes run in the workflow
    ## process {
    ##     publishDir = [
    ##         path: { "${params.outdir}/${task.process.tokenize(':')[-1].tokenize('_')[0].toLowerCase()}" },
    ##         mode: params.publish_dir_mode,
    ##         saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
    ##     ]
    ##     errorStrategy = "retry"
    ##     maxRetries = 2
    ## 
    ##     //STAR-aligner process specific parameters
    ##     //https://www.nextflow.io/docs/latest/process.html#dynamic-computing-resources
    ##     withName: STAR_ALIGN {
    ##         cpus = { 4 * task.attempt }
    ##         memory = { 32.GB * task.attempt }
    ## <...>

You may use the advanced options to change computational resources
requested for different processes. The CPUs and memory parameters can
updated to request a larger amount of resources like CPUs or memory if
files are large. You may also edit the commandline parameters for
processes in the workflow using the `ext.args`
[directive](https://www.nextflow.io/docs/latest/process.html#directives).

The current TRIMGALORE paramters look like this:

    ##     //Trimgalore process specific parameters
    ##     withName: TRIMGALORE {
    ##         cpus = { 2 * task.attempt }
    ##         memory = { 8.GB * task.attempt }
    ##         ext.args = ''
    ##     }
    ## 
    ## <...>

But you’d like to request 16Gb of memory for and gzip the output.

    ##     //Trimgalore process specific parameters
    ##     withName: TRIMGALORE {
    ##         cpus = { 2 * task.attempt }
    ##         memory = { 16.GB * task.attempt }
    ##         ext.args = '--gzip'
    ##     }
    ## 
    ## <...>

# Run the workflow

Then execute a wrapper around the `nextflow run main.nf` command which
is in the `main_run.sh` shell script. Provide a descriptive name
(string) for your workflow run, in this example we will use
“my_analysis”.

Typically, you will not need to change the `main_run.sh` often.

The `main_run.sh` script defines the profiles for different executors in
the variable `NFX_PROFILE`. The choices for profiles are:

- PBS_singularity \[default\]
- local_singularity

“PBS_singularity” is recommended. This profiles executes the jobs on the
HPC using the PBS scheduler and then will run the job inside singularity
containers with the appropriate scientific software versions.

“local_singularity” is good for workflow development if you’re making a
lot of changes. This will use singularity on Cybertron, but run the jobs
on the interactive compute node that you’ve requested during “Set-up
Nextflow Environment” steps above.

    ## #!/bin/bash
    ## 
    ## set -eu
    ## DATE=$(date +%F)
    ## NFX_CONFIG=./nextflow.config
    ## #Options: PBS_singularity,local_singularity
    ## NFX_PROFILE='PBS_singularity'
    ## #Options:  rnaseq_count, prep_genome, or sra_download
    ## NFX_ENTRY='rnaseq_count'
    ## #The output prefix on filenames for reports/logs
    ## <...>

You can also change the
[`entry_point`](https://www.nextflow.io/docs/latest/dsl2.html#workflow-entrypoint)
for the workflow.

- Run only the index building step using `NFX_ENTRY='star_index'`.
- Run only the download step for SRA files by setting
  `NFX_ENTRY='sra_fastqs'`.
- Keep the default `NFX_ENTRY='rnaseq_count'` to run the complete
  pipeline.

``` bash
./main_run.sh "my_analysis"
```

# Expected Outputs

Under the path provided in the nextflow config for params “outdir”, you
will find directories named for each of the modules. Lets say
“params.outdir = ./results”. There will be the following file structure:

results/

- fastqc/
  - fastqc\_{sample_id}\_/
- multiqc/
  - {sample_sheet_basename}\_multiqc_report_data/
  - collects fastqc, star alignment, and star quantification stats
- picard/
  - {sample_id}.bam
  - {sample_id}.MarkDuplicates.metrics.txt
- rseqc/
  - {gft_basename}.sort.rRNA.bed
  - {sample_id}.rRNA_stats.out
  - {sample_id}.in.bam - rRNA reads
  - {sample_id}.Aligned.sortedByCoord.out.summary.txt
  - {sample_id}.Aligned.sortedByCoord.out.tin.xls
  - {sample_id}.read_distribution.txt
- samtools/
  - fasta index (.fai) file
  - bam index (.bai) file
- sratools/
  - {SRR_RUN_ID}.fastq.gz
  - sratoolkit config file
- star/
  - star/\[SA, SAindex, etc\] - optional star index files if build_index
    = true
  - {sample_id}.Aligned.out.bam
  - {sample_id}.Log.final.out
  - {sample_id}.Log.out
  - {sample_id}.Log.progress.out
  - {sample_id}.ReadsPerGene.out.tab
  - {sample_id}.SJ.out.tab
- ucsc/
  - {gft_basename}.genepred
  - {gft_basename}.sort.bed
  - {gft_basename}.refflat
  - {gft_basename}\_transcript.infoOut.txt

In addition, there will be an HTML report with information on where the
temp data is stored in the `workDir` path, and general run statistics
such as resource utilized versus requested, which helps with
optimization. It will also provide information on how much walltime was
used per sample, total CPU hours, etc.

The HTML file is found in `reports` directory and will have the prefix
defined on the command line when the `./main_run.sh "my_analysis"` was
invoked, so in this example it would be named
“my_analysis\_{DATE}.html”.

<img src="../images/html_report.png" width="1187" style="display: block; margin: auto;" />

There will also be a detailed nextflow log file that is useful for
de-bugging which will also be named in this example,
“my_analysis\_{DATE}\_nextflow.log”.

Finally, the pipeline will produce a DAG - Directed acyclic graph which
describes the workflow channels (inputs) and the modules. The DAG image
will be saved under `dag/` directory with the name
“my_analysis\_{DATE}\_dag.pdf”.

<img src="../images/dag.png" width="4722" style="display: block; margin: auto;" />

# Share the Data

``` bash
RESULTS="PATH/TO/PIPELINE/RESULTS/"
OUTDIR="path/to/collabs/RSS"
rsync -av $RESULTS $OUTDIR 
```

# Cleaning up Cached Data

Nextflow has an utility to
[clean](https://www.nextflow.io/docs/latest/cli.html#clean) up old work
directories and logs that are no longer needed. This can be run after
any amount of time to keep your workdir from getting too large or if
you’re running out of disk space.

This requires the session ID or session name, which can found in the
`.nextflow/history` file.

``` bash
nextflow log
nextflow clean -f [RUN NAME]
```

# Session Information

``` r
sessionInfo()
```
