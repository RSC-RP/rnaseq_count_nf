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

# put testing logic here
echo "Nothing to test in template"

echo "FINISHED TEST"
exit