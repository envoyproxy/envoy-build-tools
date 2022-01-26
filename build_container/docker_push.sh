#!/bin/bash

# Do not ever set -x here, it is a security hazard as it will place the credentials below in the
# CI logs.
set -e

# Enable docker experimental
export DOCKER_CLI_EXPERIMENTAL=enabled

CONTAINER_SHA=$(git log -1 --pretty=format:"%H" .)

echo "Building envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}"
if curl -sSLf "https://index.docker.io/v1/repositories/envoyproxy/envoy-build-${OS_DISTRO}/tags/${CONTAINER_SHA}" > /dev/null; then
  echo "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA} exists."
  # exit 0
fi

CONTAINER_TAG=${CONTAINER_SHA} "./docker_build_${OS_FAMILY}.sh"

# if [[ "${SOURCE_BRANCH}" == "refs/heads/main" ]]; then

DOCKERHUB_USERNAME=gpt4
# eek!
DOCKERHUB_PASSWORD=$(base64 --decode <<< OWY1ZTc2OWQtZWQ0ZS00MjM1LTlhNjktNDljN2Y3MjJkYmFhCg==)

if true; then
    docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"

    MANIFESTS=""
    for arch in ${IMAGE_ARCH}
    do
        docker tag "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}-${arch}" "gpt4/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}-${arch}"
        docker push "gpt4/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}-${arch}"
    done

else
    echo 'Ignoring PR branch for docker push.'
fi
