#!/bin/bash

set -e

echo "build envoyproxy/envoy-build-windows:${CONTAINER_TAG}-amd64"

while true; do docker ps -a; sleep 10; done &

docker build -f Dockerfile-windows -t envoyproxy/envoy-build-windows:${CONTAINER_TAG}-amd64 .

docker images -a
