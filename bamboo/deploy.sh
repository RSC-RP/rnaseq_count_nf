#!/bin/bash

set -euo pipefail

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

echo "TEST_SERVER=$TEST_SERVER"
echo "WEB_SERVER=$WEB_SERVER"
echo "LOG_ROOT=$LOG_ROOT"
echo "BUILD_SERVER=$BUILD_SERVER"
echo "SVC_USER=$SVC_USER"
echo "SVC_PASS=$SVC_PASS"

echo "Passed argument: $1"

echo "define artifact dir"
ART_DIR=artifacts
echo "ART_DIR=$ART_DIR"
if [[ -d $ART_DIR ]]; then 
    echo "SUCCESS: found $HOSTNAME:ART_DIR: $HOSTNAME:$(pwd)/$ART_DIR"
    ls -R $ART_DIR
else 
    echo "ERROR: couldn't find $HOSTNAME:ART_DIR: $HOSTNAME:$(pwd)/$ART_DIR"
    exit 1
fi

DEPLOY_DIR_LOG=$LOG_ROOT/RPDEV/rnaseq_count_nf/deploy
echo "DEPLOY_DIR_LOG=$DEPLOY_DIR_LOG"

echo "clean out deploy_dir_log"
if [[ -d $DEPLOY_DIR_LOG ]]; then { rm -rf $DEPLOY_DIR_LOG; } fi
if [[ ! -d $DEPLOY_DIR_LOG ]]; then { echo "SUCCESS: removed existing $DEPLOY_DIR_LOG"; } else { echo "WARNING: couldn't remove $DEPLOY_DIR_LOG"; } fi

echo creating $DEPLOY_DIR_LOG
mkdir $DEPLOY_DIR_LOG
if [[ -d $DEPLOY_DIR_LOG ]]; then { echo "SUCCESS: created $DEPLOY_DIR_LOG"; } else { echo "ERROR: couldn't create $DEPLOY_DIR_LOG"; exit 1; } fi

echo "deploy $ART_DIR"
cp -R $ART_DIR/* $DEPLOY_DIR_LOG/ || { echo "ERROR: unable to copy contents of $ART_DIR"; exit 1; }

# Often times we want to deploy to dev location by default e.g. $WEBSERVER/<website>_dev
echo "generic deploy"

echo "Passed argument: $1"
if [[ $1 == 'main' ]] || [[ $1 == 'dev' ]]; then
    # do something that needs to happen for both dev and main deploy
    echo "dev or main deploy"
    if [[ $1 == 'main' ]]; then
        # do something specific to main branch
        echo "main deploy"
    elif [[ $1 == 'dev' ]]; then
        # do something specific to dev branch
        echo "dev deploy"
    fi
fi

echo "FINISHED DEPLOYMENT"
exit
