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

# put testing logic here
echo "Nothing to test in template"

echo "FINISHED TEST"
exit