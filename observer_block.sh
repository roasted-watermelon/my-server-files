#!/usr/bin/env bash

# Changes required:
#
# Add the following delay just below [Service], above "ExecStart" in docker service
# File         : /usr/lib/systemd/system/docker.service
# Delay clause : ExecStartPre=/bin/sleep 30
#
# Add to crontab:
# sudo crontab -e
# Add the following at the end: @reboot /var/scripts/observer_block.sh
#
# Make sure the entire scripts directory is copied under /var/

script_dir=$(dirname "$(realpath "$0")")
log_file="${script_dir}/block.log"

print1() {
  echo "$(date) - $1" | tee -a "$log_file"
}

block_with_exceptions() {
  container_name="$1"

  print1 "Container: $container_name, blocking ALL access..."
  ${script_dir}/network_block.sh "$container_name" | tee -a "$log_file"
  echo

  allowed_domains=`docker inspect $container_name | jq -r '.[0].Config.Env[] | select(startswith("ALLOWED_DOMAINS=")) | split("=")[1]'`

  if [[ "$allowed_domains" == "*" ]]; then
    print1 "$container_name - unblock ALL"
    ${script_dir}/network_unblock.sh "$container_name" | tee -a "$log_file"
    echo
  else
    IFS=' '
    for domain in $allowed_domains; do
      print1 "$container_name - unblock $domain"
      ${script_dir}/network_unblock.sh "$container_name" "$domain" | tee -a "$log_file"
      echo
    done
  fi
}

print1 "Wait for 10 sec..."
sleep 10s

print1 "Wait for containers to come online, removing existing rules..."
sudo iptables -F DOCKER-USER

for container_name in $(docker ps -a --format "{{.Names}}"); do
  block_with_exceptions "$container_name"
done

docker events --filter 'event=start' --format json | while read -r event;
do
  container_name=`echo $event | jq -r '.Actor.Attributes.name'`
  block_with_exceptions "$container_name"
done
