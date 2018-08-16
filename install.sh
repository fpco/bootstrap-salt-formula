#!/usr/bin/env bash

set -eux

URL=${BOOTSTRAP_URL:=https://raw.githubusercontent.com/fpco/bootstrap-salt-formula}
BRANCH=${BOOTSTRAP_BRANCH:=master}
TMP_DIR=${BOOTSTRAP_TMP_DIR:=/tmp/bootstrap}
LOG_LEVEL=${BOOTSTRAP_LOG_LEVEL:=info}

mkdir -p ${TMP_DIR}
wget -O ${TMP_DIR}/install.sls ${URL}/${BRANCH}/install.sls
sleep 1
salt-call --log-level=${LOG_LEVEL} --local --file-root $TMP_DIR state.sls install
sleep 5
rm -rf $TMP_DIR
