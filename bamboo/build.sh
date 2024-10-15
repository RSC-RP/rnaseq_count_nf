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
echo "bamboo_test_home=$bamboo_test_home"
echo "bamboo_web_server=$bamboo_web_server"
echo "bamboo_web_home=$bamboo_web_home"
echo "bamboo_build_server=$bamboo_build_server"
echo "bamboo_build_home=$bamboo_build_home"
echo "bamboo_log_root=$bamboo_log_root"
echo "bamboo_svc_user=$bamboo_svc_user"
echo "bamboo_svc_pass=$bamboo_svc_pass"

echo "local variable assignment"
TEST_SERVER=$bamboo_test_server
TEST_HOME=$bamboo_test_home
WEB_SERVER=$bamboo_web_server
WEB_HOME=$bamboo_web_home
BUILD_SERVER=$bamboo_build_server
BUILD_HOME=$bamboo_build_home
LOG_ROOT=$bamboo_log_root
SVC_USER=$bamboo_svc_user
SVC_PASS=$bamboo_svc_pass

echo "TEST_SERVER=$TEST_SERVER"
echo "TEST_HOME=$TEST_HOME"
echo "WEB_SERVER=$WEB_SERVER"
echo "WEB_HOME=$WEB_HOME"
echo "BUILD_SERVER=$BUILD_SERVER"
echo "BUILD_HOME=$BUILD_HOME"
echo "LOG_ROOT=$LOG_ROOT"
echo "SVC_USER=$SVC_USER"
echo "SVC_PASS=$SVC_PASS"

echo "create working dir on build machine"
TEMP_DIR=$(sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "mktemp -d -p $BUILD_HOME/bamboo_tmp")
if [[ $(sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "if [[ -d $TEMP_DIR ]]; then { echo "exists"; } fi") ]]; then
    echo "SUCCESS: created $BUILD_SERVER:TEMP_DIR=$TEMP_DIR"
else 
    echo "ERROR: failed to create $BUILD_SERVER:TEMP_DIR=$TEMP_DIR"
    exit 1
fi

echo "copy repo to build machine tmp"
sshpass -f $SVC_PASS scp -r * $SVC_USER@$BUILD_SERVER:$TEMP_DIR || { echo "ERROR: couldn't copy repo to $BUILD_SERVER:$TEMP_DIR"; exit 1; }

echo "schedule the build remotely"
# creates artifacts to use in test and deploy stages
# artifacts/html    - to web server
# artifacts/app     - installed somewhere
# artifacts/shared  - shared data, code, envs or containers
sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "$TEMP_DIR/bamboo/slurm_remote.sh $TEMP_DIR/bamboo/build.slurm $TEMP_DIR"

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