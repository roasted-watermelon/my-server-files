#!/usr/bin/env bash

sudo iptables -F DOCKER-USER

for container_name in $(docker ps -a --format "{{.Names}}"); do
  if [[ "$container_name" == "cloudflare_tunnel" ]]; then
    continue
  fi
  ./network_block.sh "$container_name"
done
