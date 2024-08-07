#!/usr/bin/env bash

CONTAINER_NAME="$1"

container_id="$(docker ps -aq -f name=$CONTAINER_NAME | head -1)"
echo "Container ID for $CONTAINER_NAME - $container_id"

container_ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_id)"

echo "Deleting rules for IP - $container_ip"

until false; do
  rule_line="$(sudo iptables -L DOCKER-USER -v -n --line-numbers | grep $container_ip | head -1)"
  if [[ -z "$rule_line" ]]; then
    break
  fi
  echo "$rule_line"
  rule_number="$(echo $rule_line | awk '{print $1}')"
  sudo iptables -D DOCKER-USER $rule_number
done

