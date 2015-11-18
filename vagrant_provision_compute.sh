#!/bin/bash

# setup locales
locale-gen en_US en_US.UTF-8 zh_TW zh_TW.UTF-8
dpkg-reconfigure locales

# copy the package
cp -r /vagrant/* ~

# openstack installation
cd /root
source ./install.sh -c compute


