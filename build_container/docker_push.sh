#!/bin/bash

# Do not ever set -x here, it is a security hazard as it will place the credentials below in the
# CI logs.
set -e

CONTAINER_SHA=$(git log -1 --pretty=format:"%H" .)

echo "Building envoyproxy/envoy-build-${LINUX_DISTRO}:${CONTAINER_SHA}"
if DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect envoyproxy/envoy-build-${LINUX_DISTRO}:${CONTAINER_SHA} > /dev/null; then
  echo "envoyproxy/envoy-build-${LINUX_DISTRO}:${CONTAINER_SHA} exists."
  exit 0
fi

CONTAINER_TAG=${CONTAINER_SHA} ./docker_build.sh

if [[ "${SOURCE_BRANCH}" == "refs/heads/master" ]]; then
    # TODO: push to DockerHub

    echo ${GCP_SERVICE_ACCOUNT_KEY} | base64 --decode | gcloud auth activate-service-account --key-file=-
    gcloud auth configure-docker

    if [[ "${LINUX_DISTRO}" == "ubuntu" ]]; then
        echo "Updating gcr.io/envoy-ci/envoy-build image"
        docker tag envoyproxy/envoy-build-"${distro}":"$CONTAINER_SHA" gcr.io/envoy-ci/envoy-build:"$CONTAINER_SHA"
        docker push gcr.io/envoy-ci/envoy-build:"$CIRCLE_SHA1"
    fi
else
    echo 'Ignoring PR branch for docker push.'
fi
