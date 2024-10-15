#!/bin/bash

set -euo pipefail

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

echo "Passed argument: $1"

echo "define artifact dir"
ART_DIR=artifacts
echo "ART_DIR=$ART_DIR"
if [[ -d $ART_DIR ]]; then 
    echo "SUCCESS: found $HOSTNAME:ART_DIR: $HOSTNAME:$(pwd)/$ART_DIR"
    ls -R $ART_DIR
# else 
#     echo "ERROR: couldn't find $HOSTNAME:ART_DIR: $HOSTNAME:$(pwd)/$ART_DIR"
#     exit 1
fi

DEPLOY_DIR_LOG=$LOG_ROOT/RP/bamboo_template/deploy
echo "DEPLOY_DIR_LOG=$DEPLOY_DIR_LOG"

echo "clean out deploy_dir_log"
sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "if [[ -d $DEPLOY_DIR_LOG ]]; then { rm -rf $DEPLOY_DIR_LOG; } fi"
if [[ $(sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "if [[ ! -d $DEPLOY_DIR_LOG ]]; then { echo "does not exists"; } fi") ]]; then
    echo "SUCCESS: removed existing $DEPLOY_DIR_LOG"
else 
    echo "WARNING: couldn't remove $DEPLOY_DIR_LOG"
fi

echo creating $DEPLOY_DIR_LOG
sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "mkdir $DEPLOY_DIR_LOG"
if [[ $(sshpass -f $SVC_PASS ssh $SVC_USER@$BUILD_SERVER "if [[ -d $DEPLOY_DIR_LOG ]]; then { echo "exists"; } fi") ]]; then
    echo "SUCCESS: created $DEPLOY_DIR_LOG"
else 
    echo "ERROR: couldn't create $DEPLOY_DIR_LOG"
    exit 1
fi

# echo "deploy $ART_DIR"
# sshpass -f $SVC_PASS scp -r $ART_DIR/* $SVC_USER@$BUILD_SERVER:$DEPLOY_DIR_LOG/ || { echo "ERROR: couldn't copy repo to $BUILD_SERVER:$DEPLOY_DIR_LOG/"; exit 1; }

# Often times we want to deploy to dev location by default e.g. $WEBSERVER/<website>_dev
echo "generic deploy"

echo "Passed argument: $1"
if [[ $1 == 'main' ]] || [[ $1 == 'dev' ]]  || [[ $1 == 'latest_release' ]]; then
    # do something that needs to happen for all deployments
    echo "dev or main or latest_release deploy"
    if [[ $1 == 'latest_release' ]]; then
        # do something specific to latest_release branch
        echo "latest_release deploy"
    elif [[ $1 == 'main' ]]; then
        # do something specific to main branch
        echo "main deploy"
    elif [[ $1 == 'dev' ]]; then
        # do something specific to dev branch
        echo "dev deploy"
    fi
fi

echo "FINISHED DEPLOYMENT"
exit
