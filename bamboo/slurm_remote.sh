#!/bin/bash

set -euo pipefail

if [[ ! -f "$1" ]]; then { echo "slurm script file does not exist: $1"; exit 1; }; fi

if [[ ! -d "$2" ]]; then { echo "TEMP_DIR does not exist: $2"; exit 1; } fi

# job=$(sbatch --export=TEMP_DIR="$2" --wait $1)
# SLURM_EXIT_CODE=($?)

# get job id and log it
jobid=$(sbatch --export=TEMP_DIR="$2" $1 | cut -d ' ' -f4)
echo "jobid=$jobid"
echo "Slurm Script: $1"
echo "TEMP_DIR=$2"
SLURM_EXIT_CODE="1"
while [[ true ]]; do
  state=$(sacct --allocations --noheader --jobs $jobid --format state | tr -d '[:space:]')
  echo "Slurm $jobid state: '$state'"
  if [[ ! -z "$state" ]] && [[ "$state" != "RUNNING" ]]; then
    echo "Slurm job returned: $jobid"
    echo "Slurm Script: $1"
    echo "TEMP_DIR=$2"
    echo "Slurm exit state: $state"
    SLURM_EXIT_CODE=$(sacct --allocations --noheader --jobs $jobid --format exitcode | cut -d ':' -f1 | tr -d '[:space:]')
    # make sure if the job had timed out or was cancelled to report as error to calling script
    if [[ "$state" = "TIMEOUT" ]] || [[ "$state" = "CANCELLED+" ]]; then
      SLURM_EXIT_CODE=1
    fi
    echo SLURM_EXIT_CODE=$SLURM_EXIT_CODE
    break
  else
    echo "sleeping while waiting on Slurm job to finish: $jobid"
    sleep 10
  fi
done

echo EXIT_STATUS: $SLURM_EXIT_CODE

exit $((SLURM_EXIT_CODE))