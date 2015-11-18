#!/bin/bash


############################################################################
#Openstack HA installation script
############################################################################
#  (environment):
#     2 ext3 partitions with the same size sdb1 sdc1 for drbd sync
#     make sure to set hostname and hosts file, then reboot
#     make sure your master slave machine are active and network are fine
#     (Master machine)
#      openstack management network eth0: HA1machineIP
#     (Slave machie)
#      openstack management network eth0: HA2machineIP
#     Set host=1 to install it into host side,set to the others means
#     to install it in slave side
############################################################################



#<corosync>
#step1 : install pacemaker and corosync
#step2 : configure corosync
#step3 : start corosync
#step4 : verify cluster node (crm_mon)

#<drbd>
#step5 : create the partition
#setp6 : install drbd package
#setp7 : create the drbd resource

#<pacemaker>
#step8 : Master/Slave Integration with Pacemaker
#step9 : ha virtual ip (ipaddr)
#step10: group setting


#sudo -i

# variable setup

source ./openstack_havana_deploy/setup.conf
. ./script_util.sh

# variable setting

export HA_ENABLE=1

#host=1
HA1machineIP=${controller_node_active_ip}
HA2machineIP=${controller_node_passive_ip}
bon_addr=${corosync_bon_addr}
VIP_PUBLIC_NIC=br-ex
VIP_PUBLIC_TMP_NIC=${publicnetwork_nic_network_node}

ROOT_PASSWD=1234

# HA function


function PacemakerConfugure(){

      #configure mysql
      sudo crm configure property stonith-enabled="false"
      sudo crm configure property no-quorum-policy="ignore" \
                                  pe-warn-series-max="1000" \
                                  pe-input-series-max="1000" \
                                  pe-error-series-max="1000" \
                                  cluster-recheck-interval="5min"
      sudo crm configure primitive p_drbd_mysql ocf:linbit:drbd \
                                   params drbd_resource="mysql" \
                                   op start interval="0" timeout="90s" \
                                   op stop interval="0" timeout="180s" \
                                   op promote interval="0" timeout="180s" \
                                   op demote interval="0" timeout="180s" \
                                   op monitor interval="30s" role="Slave" \
                                   op monitor interval="29s" role="Master"
      sudo crm configure primitive p_fs_mysql ocf:heartbeat:Filesystem \
                                   params device="/dev/drbd0" directory="/var/lib/mysql" fstype="xfs" options="relatime" \
                                   op start interval="0" timeout="60s" \
                                   op stop interval="0" timeout="180s" \
                                   op monitor interval="60s" timeout="60s"
      sudo crm configure primitive p_ip_mysql ocf:heartbeat:IPaddr2 \
                                   params ip="${VIP_MySQL}" cidr_netmask="24" \
                                   op monitor interval="30s" \
                                   meta target-role="Started"
      sudo crm configure primitive p_mysql ocf:heartbeat:mysql \
                                   params additional_parameters="--bind-address=0.0.0.0" config="/etc/mysql/my.cnf" pid="/var/run/mysqld/mysqld.pid" socket="/var/run/mysqld/mysqld.sock" log="/var/log/mysql/error.log" \
                                   op monitor interval="20s" timeout="10s" \
                                   op start interval="0" timeout="120s" \
                                   op stop interval="0" timeout="120s" \
                                   meta target-role="Started"


      #configure rabbitmq
      sudo crm configure primitive p_ip_rabbitmq ocf:heartbeat:IPaddr2 \
                                   params ip="${VIP_RabbitMQ}"  cidr_netmask="24" \
                                   op monitor interval="10s"
      sudo crm configure primitive p_drbd_rabbitmq ocf:linbit:drbd \
                                   params drbd_resource="rabbitmq" \
                                   op start timeout="90s" \
                                   op stop timeout="180s" \
                                   op promote timeout="180s" \
                                   op demote timeout="180s" \
                                   op monitor interval="30s" role="Slave" \
                                   op monitor interval="29s" role="Master"
      sudo crm configure primitive p_fs_rabbitmq ocf:heartbeat:Filesystem \
                                   params device="/dev/drbd1" \
                                   directory="/var/lib/rabbitmq" \
                                   fstype="xfs" options="relatime" \
                                   op start timeout="60s" \
                                   op stop timeout="180s" \
                                   op monitor interval="60s" timeout="60s"
      sudo crm configure primitive p_rabbitmq ocf:rabbitmq:rabbitmq-server \
                                   params nodename="rabbit@localhost" \
                                   mnesia_base="/var/lib/rabbitmq" \
                                   op monitor interval="20s" timeout="10s"

       #configure mongoDB
       sudo crm configure primitive p_ip_mongo ocf:heartbeat:IPaddr2 \
                                   params ip="${VIP_Mongo}"  cidr_netmask="24" \
                                   op monitor interval="10s"
       sudo crm configure primitive p_drbd_mongo ocf:linbit:drbd \
                                   params drbd_resource="mongo" \
                                   op start timeout="90s" \
                                   op stop timeout="180s" \
                                   op promote timeout="180s" \
                                   op demote timeout="180s" \
                                   op monitor interval="30s" role="Slave" \
                                   op monitor interval="29s" role="Master"
       sudo crm configure primitive p_fs_mongo ocf:heartbeat:Filesystem \
                                   params device="/dev/drbd2" \
                                   directory="/var/lib/mongodb" \
                                   fstype="xfs" options="relatime" \
                                   op start timeout="60s" \
                                   op stop timeout="180s" \
                                   op monitor interval="60s" timeout="60s"
       sudo crm configure primitive p_mongo ocf:openstack:mongodb \
                                   params user="mongodb" binfile="/usr/bin/mongod" cmdline_options="/etc/mongodb.conf" pidfile="/var/run/mongodb/mongodb.pid" \
	                           op monitor interval="20s" timeout="10s" \
                                   op start interval="0" timeout="120s" \
                                   op stop interval="0" timeout="120s"

     
      #configure virtual IP addres for HA switching
      sudo crm configure primitive p_api-ip ocf:heartbeat:IPaddr2 \
                                   params ip=$VIP_OP  cidr_netmask="24" \
                                   op monitor interval="30s"

      #configure keystone
      sudo crm configure primitive p_keystone ocf:openstack:keystone \
                                   params config="/etc/keystone/keystone.conf" os_password="admin" os_username="admin" os_tenant_name="admin" os_auth_url="http://${VIP_OP}:5000/v2.0/" \
                                   op monitor interval="30s" timeout="45s" \
                                   meta target-role="Started"

      #configure glance
      sudo crm configure primitive p_glance-api ocf:openstack:glance-api \
                                   params config="/etc/glance/glance-api.conf" os_password="admin" os_username="admin" os_tenant_name="admin" os_auth_url="http://${VIP_OP}:5000/v2.0/" \
                                   op monitor interval="30s" timeout="45s" \
                                   meta target-role="Started"

      #configure neutron
      sudo crm configure primitive p_neutron-agent-dhcp ocf:openstack:neutron-agent-dhcp \
                                   params config="/etc/neutron/neutron.conf" \
                                   op monitor interval="30s" timeout="30s" \
                                   meta target-role="Started"
      sudo crm configure primitive p_neutron-agent-l3 ocf:openstack:neutron-agent-l3 \
                                   params config="/etc/neutron/neutron.conf" \
                                   op monitor interval="30s" timeout="30s"
      sudo crm configure primitive p_neutron-metadata-agent ocf:openstack:neutron-metadata-agent \
                                   params config="/etc/neutron/neutron.conf" \
                                   op monitor interval="30s" timeout="30s"
      sudo crm configure primitive p_neutron-server ocf:openstack:neutron-server \
                                   params config="/etc/neutron/neutron.conf" os_password="admin" os_username="admin" os_tenant_name="admin" \
                                   op monitor interval="30s" timeout="30s" \
                                   meta target-role="Started"

      #configure nova
      sudo crm configure primitive p_nova-api ocf:openstack:nova-api \
                                   params config="/etc/nova/nova.conf" \
                                   op monitor interval="10s" timeout="10s"
      sudo crm configure primitive p_nova-cert ocf:openstack:nova-cert \
                                   params config="/etc/nova/nova.conf" \
                                   op monitor interval="30s" timeout="30s"
      sudo crm configure primitive p_nova-consoleauth ocf:openstack:nova-consoleauth \
                                   params config="/etc/nova/nova.conf" \
                                   op monitor interval="30s" timeout="30s"
     # sudo crm configure primitive p_nova-novnc ocf:openstack:nova-novnc \
     #                              params config="/etc/nova/nova.conf" \
     #                              op monitor interval="30s" timeout="30s" \
     #                              meta target-role="Started"
      sudo crm configure primitive p_nova-scheduler ocf:openstack:nova-scheduler \
                                   params config="/etc/nova/nova.conf" \
                                   op monitor interval="30s" timeout="30s"

      sudo crm configure primitive p_nova-conductor ocf:openstack:nova-conductor \
                                   params config="/etc/nova/nova.conf" \
                                   op monitor interval="30s" timeout="30s"

      #configure cinder
      sudo crm configure primitive p_cinder-api ocf:openstack:cinder-api \
                                   params config="/etc/cinder/cinder.conf" os_password="admin" os_username="admin" os_tenant_name="admin" keystone_get_token_url="http://${VIP_OP}:5000/v2.0/tokens" \
                                   op monitor interval="30s" timeout="30s" \
                                   meta target-role="Started"

      #configure ceilometer
      sudo crm configure primitive p_ceilometer-agent-central ocf:openstack:ceilometer-agent-central \
                                   params config="/etc/ceilometer/ceilometer.conf" \
                                   op monitor interval="30s" timeout="30s" 

      #configure external VIP
      sudo crm configure primitive p_ip_public ocf:heartbeat:IPaddr2 \
                                   params ip="${VIP_PUBLIC}" cidr_netmask="24" nic="${VIP_PUBLIC_TMP_NIC}" \
                                   op monitor interval="30s" \
                                   meta target-role="Started"
      #configure group
#p_glance-api p_quantum-server p_quantum-agent-dhcp p_quantum-metadata-agent p_quantum-agent-l3 p_nova-api p_nova-cert p_nova-consoleauth p_nova-scheduler p_nova-novnc p_cinder-api\
      #sudo crm configure group g_mysql p_ip_mysql p_ip_public p_api-ip p_fs_mysql p_mysql p_keystone p_glance-api p_neutron-server p_neutron-agent-l3 p_neutron-agent-dhcp p_neutron-metadata-agent p_nova-api p_nova-cert p_nova-consoleauth p_nova-scheduler p_nova-novnc p_cinder-api\  
      sudo crm configure group g_mysql p_ip_mysql p_ip_public p_api-ip p_fs_mysql p_mysql p_keystone p_glance-api p_neutron-server p_nova-api p_nova-cert p_nova-consoleauth p_nova-scheduler p_nova-conductor p_cinder-api p_ceilometer-agent-central \
                               meta target-role="Started"
      sudo crm configure group g_rabbitmq p_ip_rabbitmq p_fs_rabbitmq p_rabbitmq \
                               meta target-role="Started"
      sudo crm configure group g_mongo p_ip_mongo p_fs_mongo p_mongo \
                               meta target-role="Started"
      sudo crm configure ms ms_drbd_mysql p_drbd_mysql \
                            meta notify="true" clone-max="2" target-role="Started"
      sudo crm configure ms ms_drbd_rabbitmq p_drbd_rabbitmq \
                            meta notify="true" master-max="1" clone-max="2" target-role="Started"
      sudo crm configure ms ms_drbd_mongo p_drbd_mongo \
                            meta notify="true" clone-max="2" target-role="Started"
      sudo crm configure colocation c_mysql_on_drbd inf: g_mysql ms_drbd_mysql:Master
      sudo crm configure colocation c_rabbitmq_on_drbd inf: g_rabbitmq ms_drbd_rabbitmq:Master
      sudo crm configure colocation c_mongo_on_drbd inf: g_mongo ms_drbd_mongo:Master
      sudo crm configure order o_drbd_before_mysql inf: ms_drbd_mysql:promote g_mysql:start
      sudo crm configure order o_drbd_before_rabbitmq inf: ms_drbd_rabbitmq:promote g_rabbitmq:start
      sudo crm configure order o_drbd_before_mongo inf: ms_drbd_mongo:promote g_mongo:start
      sudo crm configure order order1 inf: g_rabbitmq:start g_mysql
      
}



# script code body

. ./ha_function.sh

sudo service mysql stop
sudo service rabbitmq-server stop


#create drvd volume for mysql and rabbitmq
./drbdvg_create.sh
ShowMessage "Create drbd volume Done"
CountDown 5


#auto setup password
echo root:${ROOT_PASSWD} | sudo chpasswd
sudo apt-get install -y --force-yes sshpass




#install drbd , corosync and pacemaker package.
#drbd pacakge has compatible issue with pacemaker.
#need to install the drbd8-utils_8.3.11 to pacemaker
sudo apt-get update
#sudo dpkg -i package/ha/drbd8-utils_8.3.11-0ubuntu1_amd64.deb
#sudo dpkg -i package/ha/drbd8-utils_2%3a8.4.3-0ubuntu0.12.04.2_amd64.deb
sudo apt-get install -y --force-yes drbd8-utils
#Disable DRBD auto-start
sudo update-rc.d -f drbd remove
#load DRBD module
sudo modprobe drbd
#Add drbd to /etc/modules
sudo echo "drbd" >> /etc/modules

sudo apt-get install curl
sudo apt-get install -y --force-yes corosync pacemaker

#check drbd and pacemaker package version
ShowMessage "HA package installation complete..............."
ShowMessage "drbd8 package version:"
sudo apt-cache policy drbd8-utils
ShowMessage "corosync package version:"
sudo apt-cache policy corosync
ShowMessage "pacemaker package version:"
sudo apt-cache policy pacemaker
CountDown 5

#fake connect to setup StrictHostKeyChecking=no for ssh connection
sudo sshpass -p xx00 ssh -o StrictHostKeyChecking=no root@${HA2machineIP}
sshpass -p xx00 ssh -o StrictHostKeyChecking=no root@${HA2machineIP}
sudo sshpass -p xx00 ssh -o StrictHostKeyChecking=no root@${HA1machineIP}
sshpass -p xx00 ssh -o StrictHostKeyChecking=no root@${HA1machineIP}


if [ "$HA_ROLE" == "active" ]; then {
   #prepare hostname conf
   export HA1hostname=`hostname`
   sshpass -p ${ROOT_PASSWD} scp root@${HA2machineIP}:/etc/hostname ~
   export HA2hostname=`cat ~/hostname`
   rm ~/hostname
   #prepare corosync authkey and cp to passive node
   #if useing random dev to generate the key, it will waste a lot of time.
   #For saving time, we will generate the key via urandom dev. 
   sudo mv /dev/random /dev/random.backup
   sudo ln -s /dev/urandom /dev/random
   sudo corosync-keygen
   echo "hostname, ${HA1hostname},${HA2hostname}"
   CountDown 10
   sshpass -p ${ROOT_PASSWD} sudo scp /etc/corosync/authkey root@$HA2machineIP:/etc/corosync/authkey
   CountDown 5
   sudo rm -rf /dev/random
   sudo mv /dev/random.backup /dev/arndom

} else {
   #prepare hostname conf
   export HA2hostname=`hostname`
   sshpass -p ${ROOT_PASSWD} scp root@${HA1machineIP}:/etc/hostname ~
   export HA1hostname=`cat ~/hostname`
   rm ~/hostname
   echo "hostname, ${HA1hostname},${HA2hostname}"
   #check if corosync authkey ready in passive node
   x=0
     while [ ${x} -eq 0 ]
     do
        if [ -f /etc/corosync/authkey ]; then {
            ShowMessage "corosync authkey ready in passive node"
            break
        } else {
            ShowMessage "Wait!!! corosync authkey not readby in passive node"
            sleep 5
        };fi
     done 
};fi

#prepare hosts
echo "
$HA1machineIP	${HA1hostname}.book ${HA1hostname}
$HA2machineIP	${HA2hostname}.book ${HA2hostname}
" | sudo tee -a /etc/hosts

#must do even you manual start
sudo sed -i 's/^START=no/START=yes/g' /etc/default/corosync
#set corosync conf
sudo sed -i.bak "s/.*bindnetaddr:.*/bindnetaddr:\ $bon_addr/g" /etc/corosync/corosync.conf
sudo sed -i.bak "s/.*rrp_mode:.*/rrp_mode:       active/g" /etc/corosync/corosync.conf
#sudo sed -i.bak "s/.*ver:.*/ver:       1/g" /etc/corosync/corosync.conf
#sudo sed -i.bak "s/.*debug:.*/debug: on/g" /etc/corosync/corosync.conf
#add <config> parameter for mysqld_safe
sudo sed -i "s/--user=\$OCF_RESKEY_user \$OCF_RESKEY_additional_parameters /--user=\$OCF_RESKEY_user \$OCF_RESKEY_additional_parameters config=\$OCF_RESKEY_config /g" /usr/lib/ocf/resource.d/heartbeat/mysql

ShowMessage "corosync and pacemaker restart"
#CorosyncAndPacemakerRestart
sudo service corosync restart
      #need to wait 5 sec,otherwise pacemaker restart fail
sleep 5
sudo service pacemaker restart

CountDown 5

if [ "$HA_ROLE" == "passive" ]; then {

   ShowMessage "slave tesing, crm status"
   sudo corosync-cfgtool -s
   sudo corosync-objctl runtime.totem.pg.mrp.srp.members
   sudo crm status

} else {

   ShowMessage "wait for slave complete, testing in slave...."

};fi


sudo service pacemaker stop
ShowMessage "corosync setup Done..............."
CountDown 5



#/etc/drbd.d/mysql.res
sudo rm -r  /etc/drbd.d/mysql.res
cat <<-END | sudo tee -a /etc/drbd.d/mysql.res
resource mysql {
   device /dev/drbd0;
   disk /dev/mapper/drbdvg-mysqllv;
   meta-disk internal;
   protocol C;   
   on ${HA1hostname}
   {  
      address ipv4 ${HA1machineIP}:7788;
   }
   on ${HA2hostname}
   {  
      address ipv4 ${HA2machineIP}:7788;
   }
   syncer {
                rate 40M;
   }
   net {
        after-sb-0pri discard-zero-changes;
        after-sb-1pri discard-secondary;
   }
}
END

sudo rm -r  /etc/drbd.d/rabbitmq.res
cat <<-END | sudo tee -a /etc/drbd.d/rabbitmq.res
resource rabbitmq{
   device  /dev/drbd1;
   disk /dev/mapper/drbdvg-rabbitmqlv;
   meta-disk internal;
   protocol C;
   on ${HA1hostname}
   {  
      address ipv4 ${HA1machineIP}:7789;
   }
   on ${HA2hostname}
   {  
      address ipv4 ${HA2machineIP}:7789;
   }
   syncer {
                rate 40M;
   }
   net {
        after-sb-0pri discard-zero-changes;
        after-sb-1pri discard-secondary;
   }

}
END

sudo rm -r  /etc/drbd.d/mongo.res
cat <<-END | sudo tee -a /etc/drbd.d/mongo.res
resource mongo{
   device  /dev/drbd2;
   disk /dev/mapper/drbdvg-mongolv;
   meta-disk internal;
   protocol C;
   on ${HA1hostname}
   {  
      address ipv4 ${HA1machineIP}:7790;
   }
   on ${HA2hostname}
   {  
      address ipv4 ${HA2machineIP}:7790;
   }
   syncer {
                rate 40M;
   }
   net {
        after-sb-0pri discard-zero-changes;
        after-sb-1pri discard-secondary;
   }

}
END


#[Both node]Once the configuration file is saved, we can test its correctness as follows:
sudo drbdadm dump mysql
sudo drbdadm dump rabbitmq
sudo drbdadm dump mongo


#[Both node]Create the metadata as follows:
sudo drbdadm create-md mysql #both node
sudo drbdadm create-md rabbitmq #both node
sudo drbdadm create-md mongo #both node

#[Both node]Bring resources up:
sudo drbdadm up mysql
sudo drbdadm up rabbitmq
sudo drbdadm up mongo

sudo drbd-overview

ShowMessage "drbd overview status"
CountDown 5 

#sudo service drbd start

if [ "$HA_ROLE" == "active" ]; then {
    #set primary node master side only
#    CheckDRBDrReady_1 "mysql"
#    CheckDRBDrReady_1 "rabbitmq"

    echo  "primary machine"
    sudo drbdadm -- --overwrite-data-of-peer primary mysql
    CheckDRBDrReady "mysql"
    sudo drbdadm -- --overwrite-data-of-peer primary rabbitmq
    CheckDRBDrReady "rabbitmq"
    sudo drbdadm -- --overwrite-data-of-peer primary mongo
    CheckDRBDrReady "mongo"
    sudo mkfs.xfs /dev/drbd0 #primary node
    sudo mkfs.xfs /dev/drbd1 #primary node
    sudo mkfs.xfs /dev/drbd2 #primary node
    #sudo mount /dev/drbd0 /mnt
    
    ShowMessage "Check DRBD status :"

    CheckDRBDrReady "mysql"
    CheckDRBDrReady "rabbitmq"

    ShowMessage "mysql DRBD volume ready"
    CountDown 5
    

    #install and setup mysql for drbd
    sudo mkdir /var/lib/mysql
    sudo mount /dev/drbd0 /var/lib/mysql
    sudo mkdir /var/lib/rabbitmq
    sudo mount /dev/drbd1 /var/lib/rabbitmq
    sudo mkdir /var/lib/mongodb
    sudo mount /dev/drbd2 /var/lib/mongodb

    ##./mysql.sh
    # install mysql rabbitmq
    ./install.sh -c init

    #ToDo function disable_service mysql -->
    #target_file=/etc/init/mysql.conf
    #Replace "start on runlevel [2345]" "#start on runlevel [2345]" "${target_file}"
    sudo sed -i 's/^start on runlevel/#start on runlevel/g' /etc/init/mysql.conf
    sudo service mysql stop
    #<--

    CountDown 2

    sudo umount -l /var/lib/mysql
    sudo drbdadm secondary mysql

    

    sshpass -p ${ROOT_PASSWD} sudo scp /var/lib/rabbitmq/.erlang.cookie root@${HA2machineIP}:/var/lib/rabbitmq/
    sshpass -p ${ROOT_PASSWD} ssh root@${HA2machineIP} -t 'chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie'

    #ToDo function disable_service rabbitmq--> 
    sudo update-rc.d -f  rabbitmq-server remove
    sudo service rabbitmq-server stop
    #<--

    CountDown 2
    sudo cp /var/lib/rabbitmq/.erlang.cookie ~
    sudo umount -l /var/lib/rabbitmq
    sudo drbdadm secondary rabbitmq
    sudo cp ~/.erlang.cookie /var/lib/rabbitmq/
    sudo chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

    echo "Active node : rabbitmq erlang.cookie"
    sudo cat /var/lib/rabbitmq/.erlang.cookie

    echo "Passive node : rabbitmq erlang.cookie"
    sshpass -p ${ROOT_PASSWD} ssh root@${HA2machineIP} -t 'cat /var/lib/rabbitmq/.erlang.cookie'

    sudo apt-get install -y --force-yes mongodb
    CountDown 1
    sudo service mongodb stop
    sudo umount -l /var/lib/mongodb
    sudo drbdadm secondary mongo

    CountDown 2

#    ShowMessage "corosync and packmaker restart"
#    CorosyncAndPacemakerRestart
    sudo service pacemaker restart
    ShowMessage "corosync and packmaker restart complete"

    CountDown 2

    OcfResourceInstallForOpenStack
    PacemakerConfugure

    #sudo crm resource cleanup p_fs_mysql
    #sudo crm resource cleanup p_mysql
    #sudo crm resource cleanup p_drbd_mysql
    #sudo crm resource cleanup g_rabbitmq
    #sudo crm resource cleanup p_rabbitmq
    #sudo crm resource cleanup p_drbd_rabbitmq

    CountDown 2
    sudo crm node standby
    CountDown 2
    sshpass -p ${ROOT_PASSWD} ssh root@${HA2machineIP} -t 'crm node standby'
    sudo crm resource cleanup g_rabbitmq
    CountDown 2
    sudo crm resource cleanup g_mysql
    sudo crm resource cleanup p_fs_mysql
    sudo crm resource cleanup p_mysql
    sudo crm resource cleanup p_drbd_mysql
    sudo crm resource cleanup g_rabbitmq
    sudo crm resource cleanup p_rabbitmq
    sudo crm resource cleanup p_drbd_rabbitmq
    CountDown 10
    sudo crm node online
    CheckCrmStatus MySQL
    CheckCrmStatus Rabbitmq
    CheckCrmStatus VIP
    ./install.sh -c keystone
    ./stop-openstack
    sudo crm resource cleanup g_mysql
    CheckCrmStatus Keystone
    CountDown 2
    ./install.sh -c glance
    CountDown 2
    ./stop-openstack
    #p_glance-api p_neutron-server p_nova-api p_nova-cert p_nova-consoleauth p_nova-scheduler p_cinder-api
    #sudo crm resource cleanup g_mysql 
    sudo crm resource cleanup p_glance-api
    CheckCrmStatus Keystone
    CheckCrmStatus Glance

    ./install.sh -c neutron
    ./stop-openstack
    #sudo crm resource cleanup g_mysql
    sudo crm resource cleanup p_neutron-server

    CheckCrmStatus MySQL
    CheckCrmStatus Rabbitmq
    CheckCrmStatus VIP
    CheckCrmStatus Keystone
    CheckCrmStatus Glance
    CheckCrmStatus Neutron

    CountDown 5
    ./install.sh -c nova
    ./stop-openstack
    #sudo crm resource cleanup g_mysql
    sudo crm resource cleanup p_nova-api
    sudo crm resource cleanup p_nova-cert
    sudo crm resource cleanup p_nova-consoleauth
    sudo crm resource cleanup p_nova-scheduler
    sudo crm resource cleanup p_nova-conductor
    
    CheckCrmStatus MySQL
    CheckCrmStatus Rabbitmq
    CheckCrmStatus VIP
    CheckCrmStatus Keystone
    CheckCrmStatus Glance
    CheckCrmStatus Neutron
    CheckCrmStatus Nova
    CountDown 5
    ./install.sh -c other
    ./stop-openstack
    sudo crm resource cleanup p_cinder-api
    CheckCrmStatus Cinder

    sudo crm resource cleanup p_ceilometer-agent-central
    #CheckCrmStatus Ceilometer
    CountDown 10
    PacemakerConfigureForStopPubVIP
    CountDown 5
    ./install.sh -c network
    PacemakerConfugureForPubVIP
    CountDown 5
    ./stop-openstack
    CountDown 10
    PacemakerConfigureResetGroup
    CountDown 5
    ./install.sh -c ceilometer
    ./stop-openstack
    sudo crm resource cleanup g_mysql
} else {
    echo "slave machine"

    CheckDRBDrReady_passive "mysql"
    CheckDRBDrReady_passive "rabbitmq"
    CheckDRBDrReady_Passive "mongo"

#    ShowMessage "corosync and packmaker restart"
    ./install.sh -c init

    #ToDo function disable_service mysql -->
    sudo sed -i 's/^start on runlevel/#start on runlevel/g' /etc/init/mysql.conf
    sudo service mysql stop
    #<--

    #ToDo function disable_service rabbitmq-->
    sudo update-rc.d -f  rabbitmq-server remove
    sudo service rabbitmq-server stop
    #<--

    sudo apt-get install -y --force-yes mongodb
    CountDown 1
    sudo service mongodb stop

    sudo service pacemaker restart
    OcfResourceInstallForOpenStack
    CountDown 2
    ShowMessage "corosync and packmaker restart complete"
    CountDown 4
    CheckCrmStatus MySQL
    CheckCrmStatus Rabbitmq
    CheckCrmStatus VIP
    CountDown 10
    ./install.sh -c keystone
    ./stop-openstack
    CheckCrmStatus Keystone
    CountDown 2
    ./install.sh -c glance
    ./stop-openstack
    CheckCrmStatus Keystone
    CheckCrmStatus Glance

    ./install.sh -c neutron
    ./stop-openstack
    CountDown 10

    CheckCrmStatus MySQL
    CheckCrmStatus Rabbitmq
    CheckCrmStatus VIP
    CheckCrmStatus Keystone
    CheckCrmStatus Glance
    CheckCrmStatus Neutron
    CountDown 15
    ./install.sh -c nova
    ./stop-openstack
    CheckCrmStatus MySQL
    CheckCrmStatus Rabbitmq
    CheckCrmStatus VIP
    CheckCrmStatus Keystone
    CheckCrmStatus Glance
    CheckCrmStatus Neutron
    CheckCrmStatus Nova
    CountDown 40
    ./install.sh -c other
    ./stop-openstack
    CheckCrmStatus Cinder
    #CheckCrmStatus Ceilometer
    CountDown 15
    ./install.sh -c network
    CountDown 10
    ./install.sh -c ceilometer
    ./stop-openstack
};fi


ShowMessage "HA setup Done"

CountDown 5

