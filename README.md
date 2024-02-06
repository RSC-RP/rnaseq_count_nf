# RNA-seq Alignment, QC, and Quantification Nextflow Pipeline 

This pipeline uses publically available modules from [nf-core](https://nf-co.re/) with some locally created modules. The primary functionality is to run a workflow on 10s - 1000s of samples in parallel on the Seattle Children's Cybertron HPC using the PBS job scheduler and containerized scientific software.

First, follow the steps on this page to make a personal copy of this repository. Then, the **step-by-step instructions to run the workflow: [`workflow_docs/workflow_run.md`](workflow_docs/run_workflow.md)** can be used. 

# About the Workflow

This workflow is designed to output gene expression counts from STAR aligner using [`--quantmode`](https://physiology.med.cornell.edu/faculty/skrabanek/lab/angsd/lecture_notes/STARmanual.pdf). It will also perform general QC statistics on the fastqs with [fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) and the alignment using [rseqc](https://rseqc.sourceforge.net/). Finally, the QC reports are collected into a single file using [multiQC](https://multiqc.info/).

A DAG (directed acyclic graph) of the workflow is show below:


![](images/dag.png)


# Set-up  Nextflow Environment 

## Code Repository

First, fork the [repository](https://childrens-atlassian/bitbucket/projects/RP/repos/rnaseq_count_nf/browse) from Children’s bitbucket. Do this by clicking the “create fork” symbol from the bitbucket web interface and fork it to your personal bitbucket account, as illustrated below.


![](images/bitbucket_fork1.png)
![](images/bitbucket_fork2.png)
![](images/bitbucket_fork3.png)


Next, you will need to clone your personal repository to your home in Cybertron. See the image below for where you can find the correct URL on your forked bitbucket repo. 


![](images/bitbucket_clone.png)


Copy that URL to replace `https://childrens-atlassian/bitbucket/scm/~jsmi26/rnaseq_count_nf.git` below. 

```
#on a terminal on the Cybertron login nodes
cd ~

# your fork should have your own userID (rather than jsmi26)
git clone https://childrens-atlassian/bitbucket/scm/~MY_USERID/rnaseq_count_nf.git

cd ~/rnaseq_count_nf
```

Once inside the code repository, use the latest release branch or make sure you're using the same release as prior analysis by using `git`.

```
git fetch
git branch -a
```

The git branch command will show all available remote branches, including remote branches, like:

```
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/dev
  remotes/origin/main
  remotes/origin/release/1.1.2
```

Checkout the **most current release branch**, which will be the largest value (eg use `release/1.2.0` if avaiable). You can use the most up-to-date branch by using this command:

```
git checkout release/1.0.0
```

Which will state that you are now on `release/1.0.0` branch and that it is tracking the release branch in your personal repository. 

> Checking out files: 100% (55/55), done.
> Branch release/1.0.0 set up to track remote branch release/1.0.0 from origin.
> Switched to a new branch 'release/1.0.0'

## Conda Environment

Finally, grab a compute node and activate the conda environment. It is also be best practice to use `tmux` or `screen` to ensure that if at the session is disconnected, then you’re nextflow workflow (if running) won’t end with SIGKILL error.

Find your project code by listing all your projects on the Cybertron terminal.

```
project info
```

```
# Grab a compute note
qsub -I -q freeq -l select=1:ncpus=1:mem=8g -l walltime=8:00:00 -P [PROJECT CODE]
cd /path/to/rnaseq_count_nf
```

If you don’t have conda installed yet, please follow these [directions](http://gonzo/confluence_rsc_docs/general_info.html#setting-up-conda-environments-on-cyberton). You may stop following the directions after the conda deactivate step.

Next, for the conda environment to be solved, you will need to set channel_priority to flexible in your conda configs as well. To read more about conda environments and thier configurations, check out the [documentation](https://docs.conda.io/projects/conda/en/latest/commands/config.html#conda-config). 

```
# check config settings
conda config --describe channel_priority # print your current conda settings
conda config --set channel_priority flexible # set to flexible if not already done

# Create the environement only once. Skip this step if you've already created the environment
conda env create -f env/nextflow.yaml
```

```
# Activate the conda environment. 
conda activate nextflow
```