#!/bin/bash

# Do not ever set -x here, it is a security hazard as it will place the credentials below in the
# CI logs.
set -e

# Enable docker experimental
export DOCKER_CLI_EXPERIMENTAL=enabled

CONTAINER_SHA=$(git log -1 --pretty=format:"%H" .)

echo "Building envoyproxy/envoy-build-windows:${CONTAINER_SHA}"
if curl -sSLf https://index.docker.io/v1/repositories/envoyproxy/envoy-build-windows/tags/${CONTAINER_SHA} > /dev/null; then
  echo "envoyproxy/envoy-build-windows:${CONTAINER_SHA} exists."
  exit 0
fi

CONTAINER_TAG=${CONTAINER_SHA} ./docker_build_windows.sh

if [[ "${SOURCE_BRANCH}" == "refs/heads/master" ]]; then
    docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"

    docker push envoyproxy/envoy-build-windows:${CONTAINER_SHA}-amd64

    docker manifest create --amend envoyproxy/envoy-build-windows:${CONTAINER_SHA} \
        envoyproxy/envoy-build-windows:${CONTAINER_SHA}-amd64

    docker manifest annotate envoyproxy/envoy-build-windows:${CONTAINER_SHA} \
        envoyproxy/envoy-build-windows:${CONTAINER_SHA}-amd64 \
        --os windows --arch amd64

    docker manifest push envoyproxy/envoy-build-windows:${CONTAINER_SHA}

    echo ${GCP_SERVICE_ACCOUNT_KEY} | base64 --decode | gcloud auth activate-service-account --key-file=-
    gcloud auth configure-docker --quiet

    echo "Updating gcr.io/envoy-ci/envoy-build-windows image"
    docker tag envoyproxy/envoy-build-windows:"${CONTAINER_SHA}-amd64" gcr.io/envoy-ci/envoy-build-windows:"${CONTAINER_SHA}"
    docker push gcr.io/envoy-ci/envoy-build-windows:"${CONTAINER_SHA}"

else
    echo 'Ignoring PR branch for docker push.'
fi
