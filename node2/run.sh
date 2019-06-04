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

mkdir -p data logs
chown -R 999 data logs
cp .erlang.cookie data
docker-compose up -d

wait_rabbit
docker exec rabbit rabbitmqctl stop_app
sleep 2s
docker exec rabbit rabbitmqctl join_cluster rabbit@node-1.uggla.fr
docker exec rabbit rabbitmqctl start_app
