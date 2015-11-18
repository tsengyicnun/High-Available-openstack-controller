#!/usr/bin/env bash

# Utility
. ../script_util.sh

function cinder_setup() {

  if [ ${HA_ENABLE} -eq 1 ]; then {
        echo "cinder_setup: HA_ENABLE"
        keystone_ip=${VIP_OP}
        db_ip=${VIP_MySQL}
        controller_node_ip=${VIP_OP}
        controller_node_pub_ip=${VIP_PUBLIC}
        RabbitMQ_HOST=${VIP_RabbitMQ}
  };fi
  # install packages
  install_package cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms

  # setup iscsi
  setconf infile:/etc/default/iscsitarget "false:true"
  service iscsitarget start
  service open-iscsi start

  # create database for cinder
  if [ "${HA_ROLE}" == 'none' ] || [ "${HA_ROLE}" == 'active' ]; then {
  mysql -uroot -p${mysql_pass} -e "create database cinder;"
  mysql -uroot -p${mysql_pass} -e "grant all on cinder.* to '${db_cinder_user}'@'%' identified by '${db_cinder_pass}';"
  };fi

  # set configuration files
  if [[ "$1" = "controller" ]]; then
    setconf infile:$base_dir/conf/etc.cinder/api-paste.ini \
      outfile:/etc/cinder/api-paste.ini \
      "<keystone_ip>:${keystone_ip}" \
      "<controller_pub_ip>:${controller_node_pub_ip}" \
      "<service_tenant_name>:${service_tenant_name}" \
      "<service_password>:${service_password}"
  elif [[ "$1" = "allinone" ]]; then
    setconf infile:$base_dir/conf/etc.cinder/api-paste.ini \
      outfile:/etc/cinder/api-paste.ini \
      "<keystone_ip>:${keystone_ip}" \
      "<controller_pub_ip>:${controller_node_ip}" \
      "<service_tenant_name>:${service_tenant_name}" \
      "<service_password>:${service_password}"
  else
    echo "warning: mode must be 'allinone' or 'controller'."
    exit 1
  fi
  setconf infile:$base_dir/conf/etc.cinder/cinder.conf \
    outfile:/etc/cinder/cinder.conf \
    "<db_ip>:${db_ip}" "<db_cinder_user>:${db_cinder_user}" \
    "<db_cinder_pass>:${db_cinder_pass}" \
    "<cinder_ip>:${controller_node_ip}"

  if [ ${HA_ENABLE} -eq 1 ]; then {
      target_file=/etc/cinder/cinder.conf
      Add "notifier_strategy" "notifier_strategy = rabbit" "${target_file}"
      Add "rabbit_host" "rabbit_host = ${RabbitMQ_HOST}" "${target_file}"
  };fi

  # input database for cinder
  cinder-manage db sync

  if echo "$cinder_volume" | grep "loop" ; then
    dd if=/dev/zero of=/var/lib/cinder/volumes-disk bs=1 count=0 seek=7G
    file=/var/lib/cinder/volumes-disk
    modprobe loop
    losetup $cinder_volume $file
    pvcreate $cinder_volume
    vgcreate cinder-volumes $cinder_volume
  else
    # create pyshical volume and volume group
    pvcreate ${cinder_volume}
    vgcreate cinder-volumes ${cinder_volume}
  fi

  # disable tgt daemon
  stop_service tgt
  mv /etc/init/tgt.conf /etc/init/tgt.conf.disabled
  service iscsitarget restart

  # restart all of cinder services
  service cinder-volume restart
  service cinder-api restart
  service cinder-scheduler restart
}

