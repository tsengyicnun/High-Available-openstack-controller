#!/usr/bin/env bash

# Utility
. ../script_util.sh

function heat_setup() {
  if [ ${HA_ENABLE} -eq 1 ]; then {
        echo "cinder_setup: HA_ENABLE"
        keystone_ip=${VIP_OP}
        db_ip=${VIP_MySQL}
        controller_node_ip=${VIP_OP}
        controller_node_pub_ip=${VIP_PUBLIC}
        RabbitMQ_HOST=${VIP_RabbitMQ}
  };fi
  # install packages
  install_package heat-api heat-api-cfn heat-engine

  # create database for heat
  if [ "${HA_ROLE}" == 'none' ] || [ "${HA_ROLE}" == 'active' ]; then {
  mysql -uroot -p${mysql_pass} -e "create database heat;"
  mysql -uroot -p${mysql_pass} -e "grant all on heat.* to '${db_heat_user}'@'%' identified by '${db_heat_pass}';"
  };fi

  # set configuration files
  setconf infile:$base_dir/conf/etc.heat/api-paste.ini \
    outfile:/etc/heat/api-paste.ini \
    "<keystone_ip>:${keystone_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}"

  setconf infile:$base_dir/conf/etc.heat/heat.conf \
    outfile:/etc/heat/heat.conf \
    "<db_ip>:${db_ip}" "<db_heat_user>:${db_heat_user}" \
    "<db_heat_pass>:${db_heat_pass}" \
    "<keystone_ip>:${keystone_ip}" \
    "<rabbit_ip>:${rabbit_ip}" \
    "<service_tenant_name>:${service_tenant_name}" \
    "<service_password>:${service_password}"

  # input database for heat
  if [ "${HA_ROLE}" == 'none' ] || [ "${HA_ROLE}" == 'active' ]; then {
  heat-manage db_sync
  };fi

  # restart all of cinder services
  service heat-api restart
  service heat-api-cfn restart
  service heat-engine restart
}

