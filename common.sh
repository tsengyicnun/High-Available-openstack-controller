#!/bin/bash

# Utility
. ./script_util.sh

# Condition for Debug
USE_PROXY=0
USE_LOCAL_PACKAGE=1
VAGRANT_DEBUG=1

export MessageWaitTime=2  # sec

export COMMON_User=user
export COMMON_PASSWD=1234


# IP, Username, password 

if [ ${VAGRANT_DEBUG} -eq 1 ]; then {
	echo " ============================== "
	echo " Vagrant Debug Mode"
	echo "   eth0: VirtualBox NAT usage (please don't care this)"
	echo "   Ext NIC = eth1 (please don't set address to the host's subnet)"
	echo "   Int NIC = eth2 (Management Network: eth2)"
	echo " ============================== "
	# Ext IP = 172.109.39.215 (eth1)
	export EXT_INTERFACE="eth1"
	# CONTROLLER_HOST= 10.200.20.10 (Management Network: eth2)
	export MANAGEMENT_INTERFACE="eth2"
} else {
	echo " ============================== "
	echo " Real Machine Mode"
	echo "   Ext NIC = eth0"
	echo "   Int NIC = eth1(Management Network: eth1)"
	echo " ============================== "
	CountDown 15 
	
	# Ext IP = 10.109.39.215 (eth0)
	export EXT_INTERFACE="eth0"
	# CONTROLLER_HOST= 10.200.20.10 (Management Network: eth1)
	export MANAGEMENT_INTERFACE="eth1"
};fi

if [ ${USE_PROXY} -eq 1 ]; then {
	echo " ============================== "
	echo "   Proxy Mode"
	echo " ============================== "
	
	# WARNING: PLEASE DO NOT EXPORT http_proxy and https_proxy
	#          OR YOU WILL GET ERROR MESSAGE 
	# export http_proxy=http://10.110.15.60:8080
	# export https_proxy=https://10.110.15.60:8080
	target_file=/etc/apt/apt.conf
	BackupFile ${target_file}
	
	sudo rm ${target_file}
	Append "Acquire::http::Timeout \"5\";" ${target_file}
	Append "Acquire::https::proxy \"https://10.110.15.61:8080\";" ${target_file}
	Append "Acquire::http::proxy \"http://10.110.15.61:8080\";" ${target_file}
} else {
	echo " ============================== "
	echo "   By pass proxy setup (Use Local respostory)"
	echo " ============================== "
};fi

export EXT_HOST_IP=$(ifconfig ${EXT_INTERFACE} | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
export CONTROLLER_HOST=$(ifconfig ${MANAGEMENT_INTERFACE} | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
export HOST_IP=${CONTROLLER_HOST}

export ADMIN_PASSWD=${COMMON_PASSWD}

# FLAT-MODE ONLY
export EXT_HOST_IP_FLAT_MODE

export GLANCE_HOST=${CONTROLLER_HOST}
export KEYSTONE_ENDPOINT=${CONTROLLER_HOST}
export SERVICE_TENANT_NAME=service
export SERVICE_PASS=${COMMON_PASSWD}
export ENDPOINT=${KEYSTONE_ENDPOINT}
export SERVICE_TOKEN=ADMIN
export SERVICE_PASSWD=${COMMON_PASSWD}
export SERVICE_ENDPOINT=http://${ENDPOINT}:35357/v2.0

# MySQL
export MYSQL_USER=${COMMON_User}
export MYSQL_PASSWORD=${COMMON_PASSWD}
export MYSQL_HOST=${CONTROLLER_HOST}
export MYSQL_ROOT_PASS=${COMMON_PASSWD}


export keystoneUser=${COMMON_User}
export glanceUser=${COMMON_User}
export quantumUser=${COMMON_User}
export novaUser=${COMMON_User}
export cinderUser=${COMMON_User}

# Proxy Share Secret for Quantum and Nova
export SHARE_SECRET="helloOpenStack"



ShowMessage "Environment Variable Setup Done!"
#CountDown ${MessageWaitTime}
