#!/bin/bash
#SBATCH --partition=cpu-core-sponsored
#SBATCH --account=cpu-rsc-sponsored
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1
#SBATCH --mem-per-cpu=7500M
#SBATCH --time=0-00:01:00
#SBATCH --mail-type=FAIL,INVALID_DEPEND,TIME_LIMIT
#SBATCH --mail-user=RSCCoreApp@seattlechildrens.org
#SBATCH --chdir=/data/hps/assoc/private/rsc/user/svc_rsc_hpc_auto/bamboo_logs/RP/rnaseq_count_nf/logs

# --chdir=/active/taylor_s/build/RP/rnaseq_count_nf/logs/
#should we use --output to explicitly specify the output/error log file?

set -eou pipefail

# bamboo automation assumes workingdir is environment variable TEMP_DIR passed in from sbatch --export
if [[ -d $TEMP_DIR ]]; then { echo "SUCCESS: found TEMP_DIR=$TEMP_DIR"; } else { echo "ERROR: couldn't find TEMP_DIR=$TEMP_DIR"; exit 1; } fi
cd $TEMP_DIR

echo "Do build stuff"

echo "create artifact dir"
mkdir -p artifacts

echo "place build artifacts into artifacts dir"
# echo "bar" > artifacts/foo.txt

exit