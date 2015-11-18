#!/usr/bin/env bash

# Utility
. ../script_util.sh

function glance_setup() {
  if [ ${HA_ENABLE} -eq 1 ]; then {
        echo "keysonte script: HA_ENABLE"
        keystone_ip=${VIP_OP}
        db_ip=${VIP_MySQL}
        RabbitMQ_HOST=${VIP_RabbitMQ}
  };fi
  # install packages
  install_package glance

  # create database for keystone service
  if [ "${HA_ROLE}" == 'none' ] || [ "${HA_ROLE}" == 'active' ]; then {
  mysql -uroot -p${mysql_pass} -e "create database glance;"
  mysql -uroot -p${mysql_pass} -e "grant all on glance.* to '${db_glance_user}'@'%' identified by '${db_glance_pass}';"
  };fi

  # set configuration files
  setconf infile:$base_dir/conf/etc.glance/glance-api.conf \
    outfile:/etc/glance/glance-api.conf \
    "<keystone_ip>:${keystone_ip}" "<db_ip>:${db_ip}" \
    "<db_glance_user>:${db_glance_user}" \
    "<db_glance_pass>:${db_glance_pass}"
  setconf infile:$base_dir/conf/etc.glance/glance-registry.conf \
    outfile:/etc/glance/glance-registry.conf \
    "<keystone_ip>:${keystone_ip}" "<db_ip>:${db_ip}" \
    "<db_glance_user>:${db_glance_user}" \
    "<db_glance_pass>:${db_glance_pass}"
  setconf infile:$base_dir/conf/etc.glance/glance-registry-paste.ini \
    outfile:/etc/glance/glance-registry-paste.ini \
    "<keystone_ip>:${keystone_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}"
  setconf infile:$base_dir/conf/etc.glance/glance-api-paste.ini \
    outfile:/etc/glance/glance-api-paste.ini \
    "<keystone_ip>:${keystone_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}"

  if [ ${HA_ENABLE} -eq 1 ]; then {
             target_file="/etc/glance/glance-api.conf"
             Replace "registry_host" "registry_host = ${keystone_ip}" "${target_file}"
             Replace "notifier_strategy" "notifier_strategy = rabbit" "${target_file}"
             Replace "rabbit_host" "rabbit_host = ${RabbitMQ_HOST}" "${target_file}"
             target_file="/etc/glance/glance-registry.conf"
             Replace "sql_connection" "sql_connection = mysql://${db_glance_user}:${db_glance_pass}@${keystone_ip}/glance" "${target_file}"
  };fi


  # restart process and syncing database
  restart_service glance-registry
  restart_service glance-api

  # input glance database to mysqld
  glance-manage db_sync
}

function os_add () {
  # backup exist os image
  if [[ -f ./os.img ]]; then
    mv ./os.img ./os.img.bk
  fi

  if [ ! -e ~/image/cirros-0.3.1~pre4-x86_64-disk.img ]; then

  # download cirros os image
  	wget --no-check-certificate ${os_image_url} -o ./os.img

  	# add os image to glance
  	glance image-create --name="${os_image_name}" --is-public true --container-format bare --disk-format qcow2 < ./os.img
  else
  	glance image-create --name "cirros-0.3.1~pre4-x86_64-disk" --is-public true --container-format bare --disk-format qcow2 --file ~/image/cirros-0.3.1~pre4-x86_64-disk.img
  fi
}

