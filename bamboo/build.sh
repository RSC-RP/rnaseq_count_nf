#!/bin/bash

# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# 1) -e exit immediately if any command fails
#    * N.B. Using set -e causes unintuitive error with bash arithmetic increment
#    * https://stackoverflow.com/questions/49072730/using-set-e-in-a-script-prevents-var-increment-in-bash
# 2) -u exit/fail if there any unset variables (this I've found to be SUPER helpful when I modify a variable name, and then later try to the use old variable name)
# 3) -o pipefail is to ensure a one-liner piped command will fail/exit if any commands in the pipe fail.
#
# Helpful document for working with strict mode scripts
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

# Normally unnecessary, but if you need to check on status and/or start the Bamboo agent:
# start Bamboo agent on rplbam01
# check on agent status
#   sudo systemctl status bamboo-agent
# manually start the service
#   sudo systemctl start bamboo-agent.service

# make this file executable in the repo: https://medium.com/@akash1233/change-file-permissions-when-working-with-git-repos-on-windows-ea22e34d5cee
# see current file permissions (last 3 digits of the first 6 digits) from the following command
#   git ls-files --stage
# set executable with the following command
#   git update-index --chmod=+x 'name-of-shell-script'

# Bamboo will fail the task if a non-zero exit code is detected.
# We use conditional tests to determine errors and exit 1 on error.
# Check all the reasonable things to reduce false positives in Bamboo.
# i.e. Check explicity when you can and generically when you must.

# https://unix.stackexchange.com/questions/267660/difference-between-parentheses-and-braces-in-terminal/267661#267661
# Make sure to run conditional tests using 'if/else/fi' and always use in braces '{}'
# executing commands within braces will enable exit 1 commands to properly execute for Bamboo to catch the error and stop the task
# https://stackoverflow.com/questions/3427872/whats-the-difference-between-and-in-bash/3427931#3427931
# When using conditionals, it's better to use double brackets '[[]]' instead of single brackets '[]'
#
# if [[ -d $TEMP_DIR ]]; then { echo "SUCCESS: found $HOSTNAME:TEMP_DIR=$TEMP_DIR"; } else { echo "ERROR: couldn't find $HOSTNAME:TEMP_DIR=$TEMP_DIR"; exit 1; } fi

# https://serverfault.com/questions/103174/check-to-see-if-a-directory-exists-remotely-shell-script/106013#106013
# to test for something on a remote host, it's best to use this syntax
#   N.B the `echo "exists"` in ssh example, will NOT show in the log as that is on the remote execution to specifically handle success.
#   The unhandled remote else clause will properly throw an error detectable to local if clause
#
# if [[ $(sshpass -f $SVC_PASS ssh $SVC_USER@$TEST_SERVER "if [[ -d $TEMP_DIR ]]; then { echo "exists"; } fi") ]]; then
#     echo "SUCCESS: found $TEST_SERVER:TEMP_DIR=$TEMP_DIR"
# else 
#     echo "ERROR: couldn't find $TEST_SERVER:TEMP_DIR=$TEMP_DIR"
#     exit 1
# fi

echo "build on HPC with user:"
echo USER=$USER

echo "bamboo project variables"
echo "bamboo_test_server=$bamboo_test_server"
echo "bamboo_web_server=$bamboo_web_server"
echo "bamboo_log_root=$bamboo_log_root"
echo "bamboo_build_server=$bamboo_build_server"
echo "bamboo_svc_user=$bamboo_svc_user"
echo "bamboo_svc_pass=$bamboo_svc_pass"

echo "local variable assignment"
TEST_SERVER=$bamboo_test_server
WEB_SERVER=$bamboo_web_server
LOG_ROOT=$bamboo_log_root
BUILD_SERVER=$bamboo_build_server
SVC_USER=$bamboo_svc_user
SVC_PASS=$bamboo_svc_pass
# positional argument from build stage script
PLAN_NAME=$1
ASSOC_DIR=$2

echo "TEST_SERVER=$TEST_SERVER"
echo "WEB_SERVER=$WEB_SERVER"
echo "LOG_ROOT=$LOG_ROOT"
echo "BUILD_SERVER=$BUILD_SERVER"
echo "SVC_USER=$SVC_USER"
echo "SVC_PASS=$SVC_PASS"

echo "create working dir on build machine"
PREFIX=$ASSOC_DIR/nextflow_outs/$PLAN_NAME
TEMP_DIR=$(sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "mkdir -p $PREFIX; mktemp -d -p $PREFIX")
if [[ $(sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "if [[ -d $TEMP_DIR ]]; then { echo "exists"; } fi") ]]; then
    echo "SUCCESS: created $BUILD_SERVER:TEMP_DIR=$TEMP_DIR"
else 
    echo "ERROR: failed to create $BUILD_SERVER:TEMP_DIR=$TEMP_DIR"
    exit 1
fi

echo "create cache dir for container images"
IMAGE_CACHE=/home/$SVC_USER/bamboo_tmp/$(basename $TEMP_DIR)
sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "mkdir -p $IMAGE_CACHE"
echo "created cache dir $IMAGE_CACHE on $BUILD_SERVER"

echo "copy repo to build machine tmp"
sshpass -f $SVC_PASS scp -r * $SVC_USER@$BUILD_SERVER:$TEMP_DIR || { echo "ERROR: couldn't copy repo to $BUILD_SERVER:$TEMP_DIR"; exit 1; }

echo "schedule the build remotely"
# creates artifacts to use in test and deploy stages
# artifacts/html    - to web server
# artifacts/app     - installed somewhere
# artifacts/shared  - shared data, code, envs or containers
# sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "$TEMP_DIR/bamboo/pbs_remote.sh $TEMP_DIR/bamboo/build.pbs $TEMP_DIR" &
WORK_DIR=$ASSOC_DIR/nextflow_temp/$PLAN_NAME
sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "TEMP_DIR=$TEMP_DIR IMAGE_CACHE=$IMAGE_CACHE WORK_DIR=$WORK_DIR $TEMP_DIR/bamboo/build_pipeline.sh" &
PIDS+=($!)
PID_NAMES+=("pipeline")
echo "remote job scheduled on $BUILD_SERVER"
echo "wait for pbs job(s) to finish running and store the exit status"
# see the follow link for details on getting exit code from background processes
# https://stackoverflow.com/questions/1570262/get-exit-code-of-a-background-process/46212640#46212640
set +e # allow false-like commands in these blocks
i=0
for pid in ${PIDS[@]}; do
    echo "waiting on ${PID_NAMES[$i]}: pid=$pid"
    wait $pid
    STATUS+=($?)
    ((i+=1))
done

echo "check exit status for errors and exit on error"
i=0
for st in ${STATUS[@]}; do
  if [[ ${st} -ne 0 ]]; then
    echo "ERROR: ${PID_NAMES[$i]}, PID: ${PIDS[$i]}, EXIT: $st"
    exit $st
  else
    echo "SUCCESS: ${PID_NAMES[$i]}, PID: ${PIDS[$i]}, EXIT: $st"
  fi
  ((i+=1))
done
set -e

ART_DIR=artifacts
echo "ART_DIR=$ART_DIR"

echo "copy build output to bamboo machine"
# defensive coding practice: remove bamboo machine $ART_DIR, should be removed per using Force clean Build option for source code checkout
if [[ -d $ART_DIR ]]; then { rm -rf $ART_DIR; } fi

echo "verify remote $ART_DIR dir exists $BUILD_SERVER:TEMP_DIR/$ART_DIR: $TEMP_DIR/$ART_DIR"
if [[ $(sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "if [[ -d $TEMP_DIR/$ART_DIR ]]; then { echo "exists"; } fi") ]]; then
    echo "SUCCESS: found $BUILD_SERVER:TEMP_DIR/$ART_DIR: $TEMP_DIR/$ART_DIR"
    sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "ls -R $TEMP_DIR/$ART_DIR"
else 
    echo "ERROR: $BUILD_SERVER:TEMP_DIR=$TEMP_DIR/$ART_DIR not found"
    exit 1
fi

echo "copy $BUILD_SERVER:$TEMP_DIR/$ART_DIR to bamboo machine: $HOSTNAME"
sshpass -f $SVC_PASS scp -r $SVC_USER@$BUILD_SERVER:$TEMP_DIR/$ART_DIR .
if [[ -d $ART_DIR ]]; then
    echo "SUCCESS: found $ART_DIR: $HOSTNAME:$(pwd)/$ART_DIR"
    ls -R $ART_DIR
else 
    echo "ERROR: $HOSTNAME:$(pwd)/$ART_DIR not found"
    exit 1
fi

echo "clean up build machine"
sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "rm -rf $TEMP_DIR"
if [[ $(sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "if [[ ! -d $TEMP_DIR ]]; then { echo "does not exists"; } fi") ]]; then
    echo "SUCCESS: removed $BUILD_SERVER:TEMP_DIR=$TEMP_DIR"
else 
    echo "ERROR: couldn't remove $BUILD_SERVER:TEMP_DIR=$TEMP_DIR"
    exit 1
fi

echo "FINISHED BUILD"
exit