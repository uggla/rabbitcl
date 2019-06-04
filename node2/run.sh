#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

if [[ -f data ]]; then
	rm -rf data logs
fi
mkdir -p data logs
chown -R 999 data logs
cp .erlang.cookie data
docker-compose up -d
