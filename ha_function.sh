#!/bin/bash

function CheckDRBDrReady(){

      drbd_resource=$1
#     local cs_ready_status="Connected"
#     local ro_ready_status="Secondary/Secondary"
#     local ds_ready_status="UpToDate/UpToDate"

     x=0
     while [ ${x} -eq 0 ]
     do
         cs_status=$(sudo service drbd status | grep ${drbd_resource} | awk -F ' ' '{print $2}')
         ro_status=$(sudo service drbd status | grep ${drbd_resource} | awk -F ' ' '{print $3}')
         ds_status=$(sudo service drbd status | grep ${drbd_resource} | awk -F ' ' '{print $4}')

         echo "cs_status = ${cs_status}, ro_status = ${ro_status}, ds_status = ${ds_status}"

         if [ "$cs_status" == "Connected" ] && [ "$ro_status" == "Primary/Secondary" ] && [ "$ds_status" == "UpToDate/UpToDate" ]; then {
              echo "${drbd_resource} drbd volume is readby, ok ok ok "
              ShowMessage "DRBD volume sync node"
              break
         } else {
              echo "warning : ${drbd_resource} drbd volume is not readby , wait!!!!!!!!!!!!!!!!!"
              echo " "
              echo " "
              sudo service drbd status
              sleep 3
        };fi
     done
}


function CheckDRBDrReady_passive(){

      drbd_resource=$1
#     local cs_ready_status="Connected"
#     local ro_ready_status="Secondary/Secondary"
#     local ds_ready_status="UpToDate/UpToDate"

     x=0
     while [ ${x} -eq 0 ]
     do
         cs_status=$(sudo service drbd status | grep ${drbd_resource} | awk -F ' ' '{print $2}')
         ro_status=$(sudo service drbd status | grep ${drbd_resource} | awk -F ' ' '{print $3}')
         ds_status=$(sudo service drbd status | grep ${drbd_resource} | awk -F ' ' '{print $4}')

         echo "cs_status = ${cs_status}, ro_status = ${ro_status}, ds_status = ${ds_status}"

         if [ "$cs_status" == "Connected" ] && [ "$ro_status" == "Secondary/Primary" ] && [ "$ds_status" == "UpToDate/UpToDate" ]; then {
              echo "${drbd_resource} drbd volume is readby, ok ok ok "
              ShowMessage "DRBD volume sync node"
              break
         } else {
              echo "warning : ${drbd_resource} drbd volume is not readby , wait!!!!!!!!!!!!!!!!!"
              echo " "
              echo " "
              sudo service drbd status
              sleep 3
        };fi
     done
}


function CorosyncAndPacemakerRestart(){
      sudo service corosync restart
      #need to wait 5 sec,otherwise pacemaker restart fail
      sleep 5
      sudo service pacemaker restart
}

function PacemakerConfigureForStopPubVIP(){
     CountDown 10
     echo "stop p_ip_public and delete the resource"
     sudo crm resource stop p_ip_public
     CountDown 20
     echo "delete p_ip_public"
     sudo crm configure delete p_ip_public
}


function PacemakerConfugureForPubVIP(){
      CountDown 10
      sudo crm configure primitive p_ip_public ocf:heartbeat:IPaddr2 \
                                   params ip="${VIP_PUBLIC}" cidr_netmask="24" nic="${VIP_PUBLIC_NIC}" \
                                   op monitor interval="30s" \
                                   meta target-role="Started"
      #sudo crm configure primitive p_ip_public ocf:heartbeat:IPaddr2 \
      #                             params ip="172.16.0.230" cidr_netmask="24" nic="br-ex" \
      #                             op monitor interval="30s" \
      #                             meta target-role="Started"
      #CountDown 10
      #sudo crm resource stop g_mysql
      #CountDown 20
      #sudo crm configure delete g_mysql
      #CountDown 10
      #sudo crm configure group g_mysql p_ip_mysql p_ip_public p_api-ip p_fs_mysql p_mysql p_keystone p_glance-api p_neutron-server p_neutron-agent-l3 p_neutron-agent-dhcp p_neutron-metadata-agent p_nova-api p_nova-cert p_nova-consoleauth p_nova-scheduler p_nova-novnc p_cinder-api \
      #                         meta target-role="Started"
      CountDown 5
}

function PacemakerConfigureResetGroup(){
      sudo crm resource stop g_mysql
      CountDown 20
      sudo crm configure delete g_mysql
      CountDown 20
      sudo crm configure group g_mysql p_ip_mysql p_ip_public p_api-ip p_fs_mysql p_mysql p_keystone p_glance-api p_neutron-server p_neutron-agent-l3 p_neutron-agent-dhcp p_neutron-metadata-agent p_nova-api p_nova-cert p_nova-consoleauth p_nova-scheduler p_nova-novnc p_nova-conductor p_cinder-api p_ceilometer-agent-central \
                               meta target-role="Started"
}

function OcfResourceInstallForOpenStack()
{
      sudo mkdir /usr/lib/ocf/resource.d/openstack
      sudo cp  ./package/ha/agent/openstack/* /usr/lib/ocf/resource.d/openstack/
}


function CheckCrmStatus()
{
     checkComponent=$1

     x=0
     while [ ${x} -eq 0 ]
     do
         p_fs_mysql_status=`sudo crm status | grep p_fs_mysql | grep -c "Started ${HA1hostname}"`
         p_ip_mysql_status=`sudo crm status | grep p_ip_mysql | grep -c "Started ${HA1hostname}"`
         p_ip_public_status=`sudo crm status | grep p_ip_public | grep -c "Started ${HA1hostname}"`
         p_api_ip_status=`sudo crm status | grep p_api-ip | grep -c "Started ${HA1hostname}"`
         p_mysql_status=`sudo crm status | grep " p_mysql" | grep -c "Started ${HA1hostname}"`
         p_ip_rabbitmq_status=`sudo crm status | grep "p_ip_rabbitmq" | grep -c "Started ${HA1hostname}"`
         p_fs_rabbitmq_status=`sudo crm status | grep "p_fs_rabbitmq" | grep -c "Started ${HA1hostname}"`
         p_keystone_status=`sudo crm status | grep "p_keystone" | grep -c "Started ${HA1hostname}"`
         p_glance_api_status=`sudo crm status | grep "p_glance-api" | grep -c "Started ${HA1hostname}"`
         p_neutron_server=`sudo crm status | grep "p_neutron-server" | grep -c "Started ${HA1hostname}"`
         p_cinder_api=`sudo crm status | grep "p_cinder-api" | grep -c "Started ${HA1hostname}"`
         p_nova_api=`sudo crm status | grep "p_nova-api" | grep -c "Started ${HA1hostname}"`
         p_nova_cert=`sudo crm status | grep "p_nova-cert" | grep -c "Started ${HA1hostname}"`
         p_nova_consoleauth=`sudo crm status | grep "p_nova-consoleauth" | grep -c "Started ${HA1hostname}"`
         p_nova_novnc=`sudo crm status | grep "p_nova-novnc" | grep -c "Started ${HA1hostname}"`
         p_nova_scheduler=`sudo crm status | grep "p_nova-scheduler" | grep -c "Started ${HA1hostname}"`
         p_nova_conductor=`sudo crm status | grep "p_nova-conductor" | grep -c "Started ${HA1hostname}"`
         p_neutron_agent_dhcp_status=`sudo crm status | grep "p_neutron-agent-dhcp" | grep -c "Started ${HA1hostname}"`
         p_neutron_metadata_agent_status=`sudo crm status | grep "p_neutron-metadata-agent" | grep -c "Started ${HA1hostname}"`
         p_neutron_agent_l3_status=`sudo crm status | grep "p_neutron-agent-l3" | grep -c "Started ${HA1hostname}"`
         p_ceilometer_agent_central_status=`sudo crm status | grep "p_ceilometer-agent-central" | grep -c "Started ${HA1hostname}"`

         if [ "${checkComponent}" == "Openvswitch" ]; then {
              if [ ${p_neutron_agent_dhcp_status} -eq 1 ] && [ ${p_neutron_metadata_agent_status} -eq 1 ] && [ ${p_neutron_agent_l3_status} -eq 1 ]; then {
                    echo "[pacemaker]OVS ready"
                    break
              };fi
         };fi
 if [ "${checkComponent}" == "Nova" ]; then {
              if [ ${p_nova_api} -eq 1 ] && [ ${p_nova_cert} -eq 1 ] && [ ${p_nova_consoleauth} -eq 1 ] && [ ${p_nova_scheduler} -eq 1 ] && [ ${p_nova_conductor} -eq 1 ]; then {
                    echo "[pacemaker]Nova ready"
                    break
              };fi
         };fi

         if [ "${checkComponent}" == "MySQL" ]; then {
              if [ ${p_fs_mysql_status} -eq 1 ] && [ ${p_ip_mysql_status} -eq 1 ] && [ ${p_mysql_status} -eq 1 ]; then {
                    echo "[pacemaker]MySQL ready"
                    break
              };fi
         };fi

         if [ "${checkComponent}" == "Rabbitmq" ]; then {
              if [ ${p_ip_rabbitmq_status} -eq 1 ] && [ ${p_fs_rabbitmq_status} -eq 1 ]; then {
                    echo "[pacemaker]Rabbitmq ready"
                    break
              };fi
         };fi

         if [ "${checkComponent}" == "VIP" ]; then {
              if [ ${p_api_ip_status} -eq 1 ] && [ ${p_ip_public_status} -eq 1 ]; then {
                    echo "[pacemaker]VIP ready"
                    break
              };fi
         };fi
 if [ "${checkComponent}" == "Keystone" ]; then {
               if [ ${p_keystone_status} -eq 1 ]; then {
                    echo "[pacemaker]Keystone ready"
                    break
              };fi
         };fi

         if [ "${checkComponent}" == "Glance" ]; then {
               if [ ${p_glance_api_status} -eq 1 ]; then {
                    echo "[pacemaker]glance ready"
                    break
              };fi
         };fi

         if [ "${checkComponent}" == "Neutron" ]; then {
              if [ ${p_neutron_server} -eq 1 ]; then {
                    echo "[pacemaker]Neutron ready"
                    break
              };fi
         };fi

         if [ "${checkComponent}" == "Cinder" ]; then {
              if [ ${p_cinder_api} -eq 1 ]; then {
                    echo "[pacemaker]Cinder ready"
                    break
              };fi
         };fi

         if [ "${checkComponent}" == "Ceilometer" ]; then {
              if [ ${p_ceilometer_agent_central_status} -eq 1 ]; then {
                    echo "[pacemaker]Ceilometer ready"
                    break
              };fi
         };fi
         echo "[pacemaker]${checkComponent} not ready, wait!!!!"
         sleep 3
     done

}

