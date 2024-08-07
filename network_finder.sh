#!/usr/bin/env bash

for container in $(docker ps -q); do
    iflink=`docker exec -it $container sh -c 'cat /sys/class/net/eth0/iflink' 2>/dev/null`
    iflink="${iflink//[[:space:]]/}"
    container_name=`docker ps -a | grep $container | awk '{print $NF}'`
    veth="-----------"
    if [[ $iflink =~ ^[0-9]+$ ]]; then
      iflink=`echo $iflink|tr -d '\r'`
      veth=`grep -l $iflink /sys/class/net/veth*/ifindex`
      veth=`echo $veth|sed -e 's;^.*net/\(.*\)/ifindex$;\1;'`
    fi
    network_name=`docker inspect $container --format='{{json .NetworkSettings.Networks }}' | jq -r 'keys[]'`
    network_id=`docker network ls -f "name=$network_name" | tail -1 | awk '{print $1}'`
    if [[ $network_id == "NETWORK" ]]; then
      network_id="------------"
    fi
    bridge_name="---------------"
    if [[ $veth != "-----------" ]]; then
      bridge_name="$(bridge link | grep $veth | awk '{print $7}')"
    fi
    echo $container:$veth:$bridge_name:$network_id:$container_name
done
