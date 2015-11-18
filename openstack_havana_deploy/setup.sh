#!/usr/bin/env bash
#
# openstack grizzly installation bash script
#     allright reserved by tomokazu hirai @jedipunkz
#
# --------------------------------------------------------------------------------------
# usage : sudo ./deploy.sh <node_type>
#   node_type    : allinone | controller | network | compute
# --------------------------------------------------------------------------------------

set -ex

# --------------------------------------------------------------------------------------
# include functions
# --------------------------------------------------------------------------------------
source ./functions
source ./init.sh
source ./keystone.sh
source ./glance.sh
source ./nova.sh
source ./neutron.sh
source ./cinder.sh
source ./heat.sh
source ./ceilometer.sh
source ./horizon.sh

# --------------------------------------------------------------------------------------
# include paramters of conf file.
# --------------------------------------------------------------------------------------
# neutron.conf has some parameters which you can set. if you want to know about each
# meaning of parameters, please see readme_parameters.md.
source ./setup.conf
  
# --------------------------------------------------------------------------------------
# check os release version
# --------------------------------------------------------------------------------------
# notice : this script was tested on precise only. 13.04 raring has a problem which
# we use gre tunneling with openvswitch. so i recommend that you use precise.
codename=$(check_codename)
if [[ $codename != "precise" ]]; then
  echo "warning: this script was tested on ubuntu 12.04 lts precise only."
  exit 1
fi

# --------------------------------------------------------------------------------------
# check your user id
# --------------------------------------------------------------------------------------
# this script need root user access on target node. if you have root user id, please
# execute with 'sudo' command.
if [[ $euid -ne 0 ]]; then
  echo "warning: this script was designed for root user."
  exit 1
fi

# --------------------------------------------------------------------------------------
# execute
# --------------------------------------------------------------------------------------

case "$1" in
  allinone)
    check_interface $host_ip allinone
    nova_ip=${host_ip};                     check_para ${nova_ip}
    cinder_ip=${host_ip};                   check_para ${cinder_ip}
    db_ip=${host_ip};                       check_para ${db_ip}
    keystone_ip=${host_ip};                 check_para ${keystone_ip}
    glance_ip=${host_ip};                   check_para ${glance_ip}
    neutron_ip=${host_ip};                  check_para ${neutron_ip}
    rabbit_ip=${host_ip};                   check_para ${rabbit_ip}
    ceilometer_ip=${host_ip};               check_para ${ceilometer_ip}
    controller_node_pub_ip=${host_pub_ip};  check_para ${controller_node_pub_ip}
    controller_node_ip=${host_ip};          check_para ${controller_node_ip}
    if [[ "$network_component" = "neutron" ]]; then
      shell_env allinone
      init
      mysql_setup
      keystone_setup neutron
      glance_setup
      os_add
      openvswitch_setup allinone
      allinone_neutron_setup
      allinone_nova_setup
      cinder_setup allinone
      horizon_setup
      heat_setup
      ceilometer_setup
      ceilometer_agent_setup allinone
      create_network
      scgroup_allow allinone
    elif [[ "$network_component" = "nova-network" ]]; then
      shell_env allinone
      init
      mysql_setup
      keystone_setup nova-network
      glance_setup
      os_add
      allinone_nova_setup_nova_network
      cinder_setup allinone
      horizon_setup
      heat_setup
      ceilometer_setup
      ceilometer_agent_setup allinone
      create_network_nova_network
      scgroup_allow allinone
    else
      echo "network_component must be 'neutron' or 'nova-network'."
      exit 1
    fi

    printf '\033[0;32m%s\033[0m\n' 'this script was completed. :D'
    printf '\033[0;34m%s\033[0m\n' 'you have done! enjoy it. :)))))'
    ;;
  controller)
    nova_ip=${controller_node_ip};              check_para ${nova_ip}
    cinder_ip=${controller_node_ip};            check_para ${cinder_ip}
    db_ip=${controller_node_ip};                check_para ${db_ip}
    keystone_ip=${controller_node_ip};          check_para ${keystone_ip}
    glance_ip=${controller_node_ip};            check_para ${glance_ip}
    neutron_ip=${controller_node_ip};           check_para ${neutron_ip}
    rabbit_ip=${controller_node_ip};            check_para ${rabbit_ip}
    ceilometer_ip=${controller_node_ip};        check_para ${ceilometer_ip}
    if [[ "$network_component" = "neutron" ]]; then
      shell_env separate
      init
      mysql_setup
      keystone_setup neutron controller
      glance_setup
      os_add
      controller_neutron_setup
      controller_nova_setup
      cinder_setup controller
      horizon_setup
      heat_setup
      ceilometer_setup
      # scgroup_allow controller
    elif [[ "$network_component" = "nova-network" ]]; then
      shell_env separate
      init
      mysql_setup
      keystone_setup nova-network controller
      glance_setup
      os_add
      #controller_neutron_setup
      controller_nova_setup_nova_network
      cinder_setup controller
      horizon_setup
      heat_setup
      ceilometer_setup
      create_network_nova_network
      # scgroup_allow controller
    else
      echo "network_component must be 'neutron' or 'nova-network'."
      exit 1
    fi
    
    printf '\033[0;32m%s\033[0m\n' 'setup for controller node has done. :D.'
    printf '\033[0;34m%s\033[0m\n' 'next, login to network node and exec "sudo ./setup.sh network".'
    ;;
  init)
    nova_ip=${controller_node_ip};              check_para ${nova_ip}
    cinder_ip=${controller_node_ip};            check_para ${cinder_ip}
    db_ip=${controller_node_ip};                check_para ${db_ip}
    keystone_ip=${controller_node_ip};          check_para ${keystone_ip}
    glance_ip=${controller_node_ip};            check_para ${glance_ip}
    neutron_ip=${controller_node_ip};           check_para ${neutron_ip}
    rabbit_ip=${controller_node_ip};            check_para ${rabbit_ip}
    ceilometer_ip=${controller_node_ip};        check_para ${ceilometer_ip}
    shell_env separate
    init
    mysql_setup
    ;;
  keystone)
    nova_ip=${controller_node_ip};              check_para ${nova_ip}
    cinder_ip=${controller_node_ip};            check_para ${cinder_ip}
    db_ip=${controller_node_ip};                check_para ${db_ip}
    keystone_ip=${controller_node_ip};          check_para ${keystone_ip}
    glance_ip=${controller_node_ip};            check_para ${glance_ip}
    neutron_ip=${controller_node_ip};           check_para ${neutron_ip}
    rabbit_ip=${controller_node_ip};            check_para ${rabbit_ip}
    ceilometer_ip=${controller_node_ip};        check_para ${ceilometer_ip}
    shell_env separate
    init
    #mysql_setup
    keystone_setup neutron controller
    ;;
  glance)
    nova_ip=${controller_node_ip};              check_para ${nova_ip}
    cinder_ip=${controller_node_ip};            check_para ${cinder_ip}
    db_ip=${controller_node_ip};                check_para ${db_ip}
    keystone_ip=${controller_node_ip};          check_para ${keystone_ip}
    glance_ip=${controller_node_ip};            check_para ${glance_ip}
    neutron_ip=${controller_node_ip};           check_para ${neutron_ip}
    rabbit_ip=${controller_node_ip};            check_para ${rabbit_ip}
    ceilometer_ip=${controller_node_ip};        check_para ${ceilometer_ip}
    shell_env separate
    init
    glance_setup
    os_add
    ;;
  neutron)
    nova_ip=${controller_node_ip};              check_para ${nova_ip}
    cinder_ip=${controller_node_ip};            check_para ${cinder_ip}
    db_ip=${controller_node_ip};                check_para ${db_ip}
    keystone_ip=${controller_node_ip};          check_para ${keystone_ip}
    glance_ip=${controller_node_ip};            check_para ${glance_ip}
    neutron_ip=${controller_node_ip};           check_para ${neutron_ip}
    rabbit_ip=${controller_node_ip};            check_para ${rabbit_ip}
    ceilometer_ip=${controller_node_ip};        check_para ${ceilometer_ip}
    shell_env separate
    init
    controller_neutron_setup
    ;;
  nova)
    nova_ip=${controller_node_ip};              check_para ${nova_ip}
    cinder_ip=${controller_node_ip};            check_para ${cinder_ip}
    db_ip=${controller_node_ip};                check_para ${db_ip}
    keystone_ip=${controller_node_ip};          check_para ${keystone_ip}
    glance_ip=${controller_node_ip};            check_para ${glance_ip}
    neutron_ip=${controller_node_ip};           check_para ${neutron_ip}
    rabbit_ip=${controller_node_ip};            check_para ${rabbit_ip}
    ceilometer_ip=${controller_node_ip};        check_para ${ceilometer_ip}
    shell_env separate
    init
    controller_nova_setup
    ;;
  other)
    nova_ip=${controller_node_ip};              check_para ${nova_ip}
    cinder_ip=${controller_node_ip};            check_para ${cinder_ip}
    db_ip=${controller_node_ip};                check_para ${db_ip}
    keystone_ip=${controller_node_ip};          check_para ${keystone_ip}
    glance_ip=${controller_node_ip};            check_para ${glance_ip}
    neutron_ip=${controller_node_ip};           check_para ${neutron_ip}
    rabbit_ip=${controller_node_ip};            check_para ${rabbit_ip}
    ceilometer_ip=${controller_node_ip};        check_para ${ceilometer_ip}
    shell_env separate
    init
    cinder_setup controller
    horizon_setup
    heat_setup
  #  ceilometer_setup
    ;;
  ceilometer)
    nova_ip=${controller_node_ip};              check_para ${nova_ip}
    cinder_ip=${controller_node_ip};            check_para ${cinder_ip}
    db_ip=${controller_node_ip};                check_para ${db_ip}
    keystone_ip=${controller_node_ip};          check_para ${keystone_ip}
    glance_ip=${controller_node_ip};            check_para ${glance_ip}
    neutron_ip=${controller_node_ip};           check_para ${neutron_ip}
    rabbit_ip=${controller_node_ip};            check_para ${rabbit_ip}
    ceilometer_ip=${controller_node_ip};        check_para ${ceilometer_ip}
    shell_env separate
    ceilometer_setup
    mongo_setu
    ;;
  network)
    #check_interface $network_node_ip network
    nova_ip=${controller_node_ip};     check_para ${nova_ip}
    cinder_ip=${controller_node_ip};   check_para ${cinder_ip}
    db_ip=${controller_node_ip};       check_para ${db_ip}
    keystone_ip=${controller_node_ip}; check_para ${keystone_ip}
    glance_ip=${controller_node_ip};   check_para ${glance_ip}
    neutron_ip=${controller_node_ip};  check_para ${neutron_ip}
    rabbit_ip=${controller_node_ip};   check_para ${rabbit_ip}
    ceilometer_ip=${controller_node_ip};        check_para ${ceilometer_ip}
    shell_env separate
    init
    openvswitch_setup network
    network_neutron_setup
    #create_network
    #scgroup_allow controller

    printf '\033[0;32m%s\033[0m\n' 'setup for network node has done. :D'
    printf '\033[0;34m%s\033[0m\n' 'next, login to compute node and exec "sudo ./setup.sh compute".'
    ;;
  compute)
    nova_ip=${controller_node_ip};     check_para ${nova_ip}
    cinder_ip=${controller_node_ip};   check_para ${cinder_ip}
    db_ip=${controller_node_ip};       check_para ${db_ip}
    keystone_ip=${controller_node_ip}; check_para ${keystone_ip}
    glance_ip=${controller_node_ip};   check_para ${glance_ip}
    neutron_ip=${controller_node_ip};  check_para ${neutron_ip}
    rabbit_ip=${controller_node_ip};   check_para ${rabbit_ip}
    ceilometer_ip=${controller_node_ip};        check_para ${ceilometer_ip}
    if [[ "$network_component" = "neutron" ]]; then
      shell_env separate
      init
      compute_openvswitch_setup
      compute_neutron_setup
      compute_nova_setup
      ceilometer_agent_setup compute
    elif [[ "$network_component" = "nova-network" ]]; then
      shell_env separate
      init
      compute_nova_setup_nova_network
      ceilometer_agent_setup compute
    else
      echo "network_component must be 'neutron' or 'nova-network'."
      exit 1
    fi

    compute_interface
    

    printf '\033[0;32m%s\033[0m\n' 'setup for compute node has done. :D'
    printf '\033[0;34m%s\033[0m\n' 'you have done! enjoy it. :)))))'
    ;;
  create_network)
    nova_ip=${controller_node_ip};              check_para ${nova_ip}
    cinder_ip=${controller_node_ip};            check_para ${cinder_ip}
    db_ip=${controller_node_ip};                check_para ${db_ip}
    keystone_ip=${controller_node_ip};          check_para ${keystone_ip}
    glance_ip=${controller_node_ip};            check_para ${glance_ip}
    neutron_ip=${controller_node_ip};           check_para ${neutron_ip}
    rabbit_ip=${controller_node_ip};            check_para ${rabbit_ip}
    shell_env separate
    create_network
    scgroup_allow controller
    ;;
   create_flat_network)
    nova_ip=${controller_node_ip};              check_para ${nova_ip}
    cinder_ip=${controller_node_ip};            check_para ${cinder_ip}
    db_ip=${controller_node_ip};                check_para ${db_ip}
    keystone_ip=${controller_node_ip};          check_para ${keystone_ip}
    glance_ip=${controller_node_ip};            check_para ${glance_ip}
    neutron_ip=${controller_node_ip};           check_para ${neutron_ip}
    rabbit_ip=${controller_node_ip};            check_para ${rabbit_ip}
    shell_env separate
    create_flat_network
    scgroup_allow controller
    ;;
  *)
    print_syntax
    ;;
esac

exit 0
