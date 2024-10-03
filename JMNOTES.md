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
     -profile sasquatch_apptainer  \
     -resume

```

Troubleshooting: 
    I had to manually pull some of the containers: 
        apptainer pull docker://quay.io/biocontainers/samtools:1.17--h00cdaf9_0
        apptainer pull docker://quay.io/biocontainers/rseqc:3.0.1--py37h516909a_1

    
Notes on Running Pipeline:
    Currently Jenny has it set up to open an interactive session and then run a PBS script. 
    When you submit the nextflow job, it's going to run with the resources allocated in the .config file- so we really don't need to open an interactive session here, unless we want to override the .config file. 

    Tried running this with just the .sh and it worked! So, that's good. It looks like we don't need to change the resources part of the config.