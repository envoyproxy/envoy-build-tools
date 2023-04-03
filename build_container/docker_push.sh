#!/bin/bash

# Do not ever set -x here, it is a security hazard as it will place the credentials below in the
# CI logs.
set -e

function is_azp {
  [[ -n "${BUILD_REASON}" ]]
}

function ci_log_run() {
  if is_azp; then
    echo "##[group]${*}"
  fi

  "${@}"

  if is_azp; then
    echo "##[endgroup]"
  fi
}

# Enable docker experimental
export DOCKER_CLI_EXPERIMENTAL=enabled

CONTAINER_SHA="$(git log -1 --pretty=format:"%H" .)"

echo "Building envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}"
if curl -sSLf "https://index.docker.io/v1/repositories/envoyproxy/envoy-build-${OS_DISTRO}/tags/${CONTAINER_SHA}" &> /dev/null; then
  echo "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA} exists."
  exit 0
fi

CONTAINER_TAG="${CONTAINER_SHA}"

IMAGE_TAGS=()

if [[ "${SOURCE_BRANCH}" == "refs/heads/main" ]]; then
    docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"
    IMAGE_TAGS+=("envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}")

    if [[ "${PUSH_GCR_IMAGE}" == "true" ]]; then
        echo ${GCP_SERVICE_ACCOUNT_KEY} | base64 --decode | gcloud auth activate-service-account --key-file=-
        gcloud auth configure-docker --quiet
        IMAGE_TAGS+=("gcr.io/envoy-ci/${GCR_IMAGE_NAME}:${CONTAINER_SHA}")
    fi
fi

source "./docker_build_${OS_FAMILY}.sh"

if [[ "${#IMAGE_TAGS[@]}" == "0" ]]; then
  echo 'Ignoring PR branch for docker push.'
fi
