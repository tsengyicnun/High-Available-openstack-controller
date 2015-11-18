#!/bin/bash
source ./openstack_havana_deploy/setup.conf
. ./script_util.sh


ShowMessage "create drbd volume:"
CountDown ${MessageWaitTime}

sudo apt-get install -y --force-yes xfsprogs

if [ ${real_machine_deploy} -eq 0 ]; then {

#sudo dd if=/dev/zero of=/vagrant/blockfile bs=1k count=4500000
#sudo dd if=/dev/zero of=/vagrant/blockfile bs=1 count=0 seek=7G
#sudo losetup /dev/loop0 /vagrant/blockfile
hdd="/dev/sdb"
for i in $hdd;do
echo "n
p
1


t
8e
w
"|sudo fdisk $i;done
sudo pvcreate /dev/sdb
sudo vgcreate drbdvg /dev/sdb
sudo lvcreate -L 4500m -n mysqllv drbdvg
sudo lvcreate -L 500m -n rabbitmqlv drbdvg
sudo lvcreate -L 4000m -n mongolv drbdvg

};fi

CountDown ${MessageWaitTime}
