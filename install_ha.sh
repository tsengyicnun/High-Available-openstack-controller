#!/bin/bash

components=(haopenstack)

# Helper functions #############################################################

function print_help {
   /bin/cat <<__EOT
Usage : 
./install -c [component name]

ex:
./install -c glance
./install -c controller active
./install -c controller passive

Options:
-c (--component) : 
__EOT

for ((i=0; i<${#components[@]}; i++)); do
	echo ${components[$i]}
done
}

if [ ! $1 ] || [ ! $2 ] ; then
	echo "component not exist"
	print_help
	return 0
fi
# Parse command line options
while [ "$1" ]; do
	case "$1" in
	-h | --help)
	print_help
	return 0
	;;
	-c |--component)
	target=$2
	shift 2
	;;
        -m | --mode)
        ha_role=$2
        shift 2
        ;;
	*)
	print_help
	return 0
    ;;
	esac
done

# Utility
. ./script_util.sh

# variable setup	
source ./common.sh;

target_file=./openstack_havana_deploy/setup.conf
Replace "HA_ENABLE" "HA_ENABLE=1" "${target_file}"

Replace "HA_ROLE" "HA_ROLE='none'" "${target_file}"

if [ "$ha_role" == "active" ]; then {
        export HA_ROLE="active"
        Replace "HA_ROLE" "HA_ROLE='active'" "${target_file}"
};fi

if [ "$ha_role" == "passive" ]; then {
        export HA_ROLE="passive"
        Replace "HA_ROLE" "HA_ROLE='passive'" "${target_file}"
};fi

# Setup deb respository
if [ ${USE_LOCAL_PACKAGE} -eq 1 ]; then {
	# local deb
	ShowMessage "Use the local deb repository"
	#sudo cp /etc/apt/sources.list /etc/apt/sources.list.org
	BackupFile "/etc/apt/sources.list"
	ORIGINAL_SOURCE_LIST_FILE=${result}
	#echo "deb file:/vagrant/package/common ./" | sudo tee /etc/apt/sources.list
        #echo "deb file:`pwd`/package/common ./" | sudo tee /etc/apt/sources.list
        #echo "deb file:`pwd`/package/gre/archives ./" | sudo tee /etc/apt/sources.list
        #echo "deb file:`pwd`/package/gre/u12.04-2/archives ./" | sudo tee /etc/apt/sources.list
        echo "deb file:`pwd`/package/ ./" | sudo tee /etc/apt/sources.list
        sudo rm /etc/apt/sources.list.d/*
} else {
	# on-line deb
	ShowMessage "Use the \"ON-LINE\" deb repository" "If you want to user local package, please USE_LOCAL_PACKAGE=1 in common.sh"

	# FIXME?  move this to the on-line deb?
	ShowMessage "Setup Grizzly Goodness repository"
	echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main" | sudo tee -a /etc/apt/sources.list.d/grizzly.list
	echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-proposed/grizzly main" | sudo tee -a /etc/apt/sources.list.d/grizzly.list

};fi

sudo apt-get update

#Install dkms
sudo apt-get install -y --force-yes dkms

# start install the openstack component
if [ "$target" == "compute" ]; then {
ShowMessage "Installing compute node"
#source ./compute_node_install.sh
pushd ./openstack_havana_deploy/
                sudo ./setup.sh compute
                popd
} else {
	for ((RR=0; RR<${#components[@]}; RR++)); do
		if [ $target == ${components[$RR]} ] || [ "$target" == "controller" ] ; then
			source ./${components[$RR]}.sh
		fi
	done
};fi

# roll back the sources.list
#sudo cp /etc/apt/sources.list.org /etc/apt/sources.list
sudo cp ${ORIGINAL_SOURCE_LIST_FILE} /etc/apt/sources.list
#sudo apt-get update

# new develop
