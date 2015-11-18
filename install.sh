#!/bin/bash

#components=(mysql other keystone create_openstack_rc verify_keystone glance quantum openvswitch nova cinder horizon)
components=(init keystone glance neutron nova other ceilometer)

# Helper functions #############################################################

function print_help {
   /bin/cat <<__EOT
Usage : 
./install -c [component name]

ex:
./install -c glance

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

# check
if [ ${VAGRANT_DEBUG} -eq 1 ]; then {
	# vagrant mode
	ShowMessage "vagrant mode: Network NIC check"
} else {
	# real machine mode
	ShowMessage "real machine mode: Network NIC check"
	# check the eth0 and eth1 link status
	if LinkTest eth0 && LinkTest eth1; then {
		echo "check ok: eth0 and eth1 link ok"		
	} else {
		#fail: eth0 or eth1 do not linked
		echo "Please check your eth0 and eth1 conection correct"
		return 1;
	};fi
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
        echo "deb file:`pwd`/package/ ./" | sudo tee /etc/apt/sources.list
        sudo rm /etc/apt/sources.list.d/*
} else {
	# on-line deb
#	ShowMessage "Use the \"ON-LINE\" deb repository" "If you want to user local package, please USE_LOCAL_PACKAGE=1 in common.sh"

	# FIXME?  move this to the on-line deb?
#	ShowMessage "Setup Grizzly Goodness repository"
#	echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main" | sudo tee -a /etc/apt/sources.list.d/grizzly.list
#	echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-proposed/grizzly main" | sudo tee -a /etc/apt/sources.list.d/grizzly.list
        sudo apt-get install ubuntu-cloud-keyring
        sudo echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-proposed/havana main > /etc/apt/sources.list.d/havana.list
        sudo apt-get update
#        sudo apt-get upgrade
#        sudo apt-get dist-upgrade
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
        if [ "$target" == "controller" ]; then {
                pushd ./openstack_havana_deploy/
                sudo ./setup.sh controller
                popd
        };fi
        if [ "$target" == "network" ]; then {
                pushd ./openstack_havana_deploy/
                sudo ./setup.sh network
                popd
        };fi
	for ((RR=0; RR<${#components[@]}; RR++)); do
		if [ $target == ${components[$RR]} ] ; then
		#	source ./${components[$RR]}.sh
                        pushd ./openstack_havana_deploy/
                        sudo ./setup.sh ${components[$RR]}
                        popd
		fi
	done
};fi

# roll back the sources.list
#sudo cp /etc/apt/sources.list.org /etc/apt/sources.list
sudo cp ${ORIGINAL_SOURCE_LIST_FILE} /etc/apt/sources.list
#sudo apt-get update

# new develop
