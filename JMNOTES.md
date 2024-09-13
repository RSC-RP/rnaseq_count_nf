Executing script: 

``` bash
# Start interactive session on sasquatch

    srun --account=cpu-rsc-sponsored --partition=cpu-core-sponsored --nodes 1 --ntasks 4 --cpus-per-task 1 --pty --mem=32G --time=15:00:00 /bin/bash

# activate mamba environment 

    mamba activate nextflow 

# Run nextflow script- identify entry points 

     nextflow    \
     -c nextflow.config  \
     run main.nf \
     -entry rnaseq_count  \
     -profile slurm_apptainer  \
     -resume

```

Troubleshooting: 
    I had to manually pull some of the containers: 
        apptainer pull docker://quay.io/biocontainers/samtools:1.17--h00cdaf9_0
        apptainer pull docker://quay.io/biocontainers/rseqc:3.0.1--py37h516909a_1

    
