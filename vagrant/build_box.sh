#!/bin/bash

SCRIPT_PATH=`realpath $0`
SCRIPT_BASE=`dirname ${SCRIPT_PATH}`
BASE_DIR="${SCRIPT_BASE}/../"
cd ${BASE_DIR} || exit 1

export ISO_IMAGE="iso/vyos-latest-amd64.iso"
export ISO_MD5_SUM=$(md5sum ${ISO_IMAGE} | awk '{print $1}')
export PACKER_BUILD_DIR="packer_build"
export PACKER_LOG_PATH="packer_build.log"
export PACKER_LOG=1

rm -rf ${PACKER_BUILD_DIR}

packer build -only=virtualbox vagrant/packer.json

cp vagrant/Vagrantfile ${PACKER_BUILD_DIR}/
cd ${PACKER_BUILD_DIR}
mv vyos.ovf box.ovf
tar cf ../box/vyos.box box.ovf vyos-disk1.vmdk Vagrantfile
cd ${BASE_DIR}

if vagrant box list | grep '^vyos '
then
	vagrant box remove -f vyos
fi
vagrant box add --name vyos box/vyos.box

