#!/bin/bash -e

set -o pipefail

# Ignore IMAGE_ARCH as amd64 is the only option
echo "build envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_TAG}"

docker build -f "Dockerfile-${OS_DISTRO}" -t "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_TAG}" .

for IMAGE_TAG in "${IMAGE_TAGS[@]}"; do
    docker tag "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_TAG}" "${IMAGE_TAG}"
    docker push "${IMAGE_TAG}"
done
