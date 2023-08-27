#!/bin/bash

# Do not ever set -x here, it is a security hazard as it will place the credentials below in the
# CI logs.
set -e

IMAGE_PREFIX="${IMAGE_PREFIX:-envoyproxy/envoy-build-}"
GCR_IMAGE_PREFIX=gcr.io/envoy-ci/


function ci_log_run() {
    if [[ -n "$CI" ]]; then
        echo "::group::${*}"
    fi
    "${@}"
    echo
    if [[ -n "$CI" ]]; then
        echo "::endgroup::"
    fi
}

# Enable docker experimental
export DOCKER_CLI_EXPERIMENTAL=enabled

CONTAINER_SHA="$(git log -1 --pretty=format:"%H" .)"

echo "Building ${IMAGE_PREFIX}${OS_DISTRO}:${CONTAINER_SHA}"
if curl -sSLf "https://index.docker.io/v1/repositories/${IMAGE_PREFIX}${OS_DISTRO}/tags/${CONTAINER_SHA}" > /dev/null; then
  echo "${IMAGE_PREFIX}${OS_DISTRO}:${CONTAINER_SHA} exists."
  exit 0
fi

CONTAINER_TAG="${CONTAINER_SHA}"

IMAGE_TAGS=()

if [[ "${SOURCE_BRANCH}" == "refs/heads/main" ]]; then
    docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"
    IMAGE_TAGS+=("${IMAGE_PREFIX}${OS_DISTRO}:${CONTAINER_SHA}")

    if [[ "${PUSH_GCR_IMAGE}" == "true" ]]; then
        echo ${GCP_SERVICE_ACCOUNT_KEY} | base64 --decode | gcloud auth activate-service-account --key-file=-
        gcloud auth configure-docker --quiet
        IMAGE_TAGS+=("${GCR_IMAGE_PREFIX}${GCR_IMAGE_NAME}:${CONTAINER_SHA}")
    fi
fi

source "./docker_build_${OS_FAMILY}.sh"

if [[ "${#IMAGE_TAGS[@]}" == "0" ]]; then
  echo 'Ignoring PR branch for docker push.'
fi
