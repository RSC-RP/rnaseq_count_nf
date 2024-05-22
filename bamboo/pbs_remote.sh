#!/bin/bash
module load pbspro/2020.1

set -euo pipefail

if [[ ! -f "$1" ]]; then { echo "PBS script file does not exist: $1"; exit 1; }; fi

if [[ ! -d "$2" ]]; then { echo "TEMP_DIR does not exist: $2"; exit 1; } fi

# query loop logic from: https://stackoverflow.com/questions/25674240/how-to-know-when-pbs-batch-jobs-are-complete
jobid=$(qsub -v TEMP_DIR="$2" $1)
echo "jobid=$jobid"
echo "PBS Script: $1"
echo "TEMP_DIR=$2"
PBS_EXIT_CODE="1"
while [[ true ]]; do
  if [[ $(qstat -xf $jobid | grep 'Exit_status = ') ]]; then
    echo "pbs job returned: $jobid"
    echo "PBS Script: $1"
    echo "TEMP_DIR=$2"
    PBS_EXIT_CODE=$(qstat -xf $jobid | grep 'Exit_status = ' | grep -o '[0-9]\+$')
    echo PBS_EXIT_CODE=$PBS_EXIT_CODE
    break
  else
    echo "sleeping while waiting on job to finish: $jobid"
    sleep 10
  fi
done

exit $((PBS_EXIT_CODE))