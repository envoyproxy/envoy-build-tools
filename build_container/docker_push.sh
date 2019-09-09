#!/bin/bash

# Do not ever set -x here, it is a security hazard as it will place the credentials below in the
# CircleCI logs.
set -e

CONTAINER_SHA=$(git log -1 --pretty=format:"%H" .)
CURRENT_SHA=$(git rev-parse HEAD)

if [[ "${CONTAINER_SHA}" != "${CURRENT_SHA}" ]]; then
    echo "The build_container directory has not changed."
    exit 0
fi

CONTAINER_TAG=${CONTAINER_SHA} ./docker_build.sh

if [[ "${SOURCE_BRANCH}" == "refs/heads/master" ]]; then
    #docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"

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
