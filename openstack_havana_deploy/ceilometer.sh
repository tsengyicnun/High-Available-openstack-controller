#!/usr/bin/env bash

function ceilometer_setup() {
    if [ ${HA_ENABLE} -eq 1 ]; then {
        echo "keysonte script: HA_ENABLE"
        controller_node_pub_ip=${VIP_OP}
        keystone_ip=${VIP_OP}
        rabbit_ip=${VIP_RabbitMQ}
    };fi
    # install packages
    install_package ceilometer-api ceilometer-collector ceilometer-agent-central python-ceilometerclient
    install_package mongodb

    setconf infile:$base_dir/conf/etc.mongodb.conf \
        outfile:/etc/mongodb.conf \
        "<controller_node_pub_ip>:${controller_node_pub_ip}"

    sudo service mongodb restart
    echo "wait for 10 sec after mongodb restart"
    sleep 10

    export LC_ALL=C

#    if [ ${HA_ENABLE} -eq 1 ]; then {
#          if [ "${HA_ROLE}" == 'none' ] || [ "${HA_ROLE}" == 'active' ]; then {
#               mongo --host ${VIP_PUBLIC} --eval "db = db.getSiblingDB(\"ceilometer\"); db.addUser({user: \"${db_ceilometer_user}\", pwd: \"${db_ceilometer_pass}\", roles: [ \"readWrite\", \"dbAdmin\" ]})"
#          };fi
#    } else {

#         mongo --host ${controller_node_pub_ip} --eval "db = db.getSiblingDB(\"ceilometer\"); db.addUser({user: \"${db_ceilometer_user}\", pwd: \"${db_ceilometer_pass}\", roles: [ \"readWrite\", \"dbAdmin\" ]})"
#    };fi

  # set configuration files
  setconf infile:$base_dir/conf/etc.ceilometer/ceilometer.conf \
    outfile:/etc/ceilometer/ceilometer.conf \
    "<controller_node_pub_ip>:${controller_node_pub_ip}" \
    "<db_ceilometer_user>:${db_ceilometer_user}" \
    "<db_ceilometer_pass>:${db_ceilometer_pass}" \
    "<ceilometer_ip>:${ceilometer_ip}" \
    "<keystone_ip>:${keystone_ip}" \
    "<rabbit_ip>:${rabbit_ip}" \
    "<service_password>:${service_password}"

  # restart all of cinder services
  restart_service ceilometer-agent-central
  restart_service ceilometer-api
  restart_service ceilometer-collector 
#  mongo --host ${VIP_PUBLIC} --eval "db = db.getSiblingDB(\"ceilometer\"); db.addUser({user: \"${db_ceilometer_user}\", pwd: \"${db_ceilometer_pass}\", roles: [ \"readWrite\", \"dbAdmin\" ]})"

}

function mongo_setu() {
    mongo --host ${VIP_OP} --eval "db = db.getSiblingDB(\"ceilometer\"); db.addUser({user: \"${db_ceilometer_user}\", pwd: \"${db_ceilometer_pass}\", roles: [ \"readWrite\", \"dbAdmin\" ]})"
}


function ceilometer_agent_setup() {
  # install packages
  install_package ceilometer-common python-ceilometer python-ceilometerclient ceilometer-agent-compute

  if [ ${HA_ENABLE} -eq 1 ]; then {
        echo "keysonte script: HA_ENABLE"
        controller_node_pub_ip=${VIP_OP}
        keystone_ip=${VIP_OP}
        rabbit_ip=${VIP_RabbitMQ}
    };fi

  # set configuration files
  if [[ "$1" = "compute" ]]; then
    setconf infile:$base_dir/conf/etc.ceilometer/ceilometer.conf \
      outfile:/etc/ceilometer/ceilometer.conf \
      "<controller_node_pub_ip>:${controller_node_pub_ip}" \
      "<db_ceilometer_user>:${db_ceilometer_user}" \
      "<db_ceilometer_pass>:${db_ceilometer_pass}" \
      "<ceilometer_ip>:${ceilometer_ip}" \
      "<keystone_ip>:${keystone_ip}" \
      "<rabbit_ip>:${rabbit_ip}" \
      "<service_password>:${service_password}"
  fi

  # restart all of cinder services
  restart_service ceilometer-agent-compute
}

