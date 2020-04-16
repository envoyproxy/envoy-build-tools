#!/bin/bash

set -e

# Ignore IMAGE_ARCH as amd64 is the only option
echo "build envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_TAG}-amd64"

docker build -f "Dockerfile-${OS_DISTRO}" -t "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_TAG}-amd64" .
