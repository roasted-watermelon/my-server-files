#!/usr/bin/env bash

CONTAINER_NAME="$1"

container_id="$(docker ps -aq -f name=$CONTAINER_NAME | head -1)"
echo "Container ID for $CONTAINER_NAME - $container_id"

container_ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_id)"

if [[ -z "$container_ip" ]]; then
  echo "No IP found!"
else
  echo "Blocking IP - $container_ip"
  sudo iptables -I DOCKER-USER -d $container_ip -o eth0 -j DROP && sudo iptables -I DOCKER-USER -s $container_ip -o eth0 -j DROP
  sudo iptables -I DOCKER-USER -d $container_ip -o wlan0 -j DROP && sudo iptables -I DOCKER-USER -s $container_ip -o wlan0 -j DROP
fi

