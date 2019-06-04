#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

wait_rabbit() {
	while ! curl -s localhost:15672 | grep "title" | grep "RabbitMQ Management"
	do
		sleep 5s
	done
}

if [[ -f data ]]; then
	rm -rf data logs
fi

node1=$(nslookup node-1.uggla.fr | sed -rn '/Name/,/Address/'p | grep "Address" | awk '{print $NF}')
node2=$(nslookup node-2.uggla.fr | sed -rn '/Name/,/Address/'p | grep "Address" | awk '{print $NF}')
node3=$(nslookup node-3.uggla.fr | sed -rn '/Name/,/Address/'p | grep "Address" | awk '{print $NF}')

iam=$(ip a s eth0 | grep inet | head -1 | awk '{print $2}' | sed -r 's#/[0-9]+##')

# Create and set data and logs ownership
mkdir -p data logs
chown -R 999 data logs
# Copy cookie file
cp .erlang.cookie data
chmod 600 data/.erlang.cookie
docker-compose up -d

# Join cluster
if [[ "${node2}" == "${iam}" ]] || [[ "${node3}" == "${iam}" ]] ;then
	wait_rabbit
	docker exec rabbit rabbitmqctl stop_app
	sleep 2s
	docker exec rabbit rabbitmqctl join_cluster rabbit@node-1.uggla.fr
	docker exec rabbit rabbitmqctl start_app
fi

if [[ "${node3}" == "${iam}" ]] ;then
	wait_rabbit
	# Set queues in HA
	docker exec rabbit rabbitmqctl set_policy ha "." '{"ha-mode":"all"}'
fi
