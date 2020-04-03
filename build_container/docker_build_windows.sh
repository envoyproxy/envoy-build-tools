#!/bin/bash

set -e

echo "build envoyproxy/envoy-build-windows:${CONTAINER_TAG}-amd64"

docker build -f Dockerfile-windows -t envoyproxy/envoy-build-windows:${CONTAINER_TAG}-amd64 .

docker images -a
