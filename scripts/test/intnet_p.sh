#!/bin/bash

SCRIPT_PATH=`realpath $0`
SCRIPT_BASE=`dirname ${SCRIPT_PATH}`
BASE_DIR="${SCRIPT_BASE}/../../"
cd ${BASE_DIR} || exit 1

for vyos in vyos1 vyos2 vyos3 vyos4 vyos5
do
	echo "####"
	echo "#### setup ${vyos}"
	echo "####"
	vagrant ssh ${vyos} -c "/vagrant/scripts/vagrant/load_boot_config.vbash" || exit 1
	vagrant ssh ${vyos} -c "/vagrant/scripts/vagrant/common_init.vbash" || exit 1
	vagrant ssh ${vyos} -c "/vagrant/scripts/vagrant/intnet_p.vbash ${vyos}" || exit 1
	echo
done

EXITCODE=0
for i in 1 2 3 4 5
	do
	for j in 1 2 3 4 5
		do
		if [ ${i} -ge ${j} ]
		then
			continue
		fi
		for k in 1 2 3 4 5
		do
			echo "####"
			echo "#### ping vyos${i}:eth${k} -> vyos${j}:eth${k}"
			echo "####"
			vagrant ssh vyos${i} -c "/bin/ping -c 5 192.168.${k}.${j}" || EXITCODE=1
			echo
		done
	done
done

exit ${EXITCODE}

