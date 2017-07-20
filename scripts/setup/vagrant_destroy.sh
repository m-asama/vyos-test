#!/bin/bash

SCRIPT_PATH=`realpath $0`
SCRIPT_BASE=`dirname ${SCRIPT_PATH}`
BASE_DIR="${SCRIPT_BASE}/../../"
cd ${BASE_DIR} || exit 1

vagrant destroy -f

