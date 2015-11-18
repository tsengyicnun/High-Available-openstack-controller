#!/bin/bash

# setup locales
locale-gen en_US en_US.UTF-8 zh_TW zh_TW.UTF-8
dpkg-reconfigure locales

# copy the package
cp -r /vagrant/* /root

# openstack installation
cd /root
source ./install.sh -c controller
source ./install.sh -c network

# create network
cd /root/openstack_havana_deploy
./setup.sh create_network

# verification
cd /root
source openstackrc
neutron agent-list
keystone user-list

# copy openstackrc to vagrant
# this code allows somebody can use following code to verify the status
# vagrant ssh controller -- 'ls -la;source ./openstackrc;neutron agent-list'
cd /root
chmod 777 openstackrc
cp openstackrc ~vagrant


