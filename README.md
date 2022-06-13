# RNA-seq Alignment, QC, and Quantification Nextflow Pipeline 

This pipeline uses publically available modules from `nf-core` with some locally created modules (rseqc splitbam.nf). 

The primary functionality will be to run a workflow on 10s - 1000s of samples in parallel on the Cybertron HPC using the PBS job scheduler and containerized scientific software. 

The step-by-step instructions to run the workflow can be found in `workflow_run.md`