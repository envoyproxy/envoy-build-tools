#!/bin/bash

# Do not ever set -x here, it is a security hazard as it will place the credentials below in the
# CI logs.
set -e

IMAGE_PREFIX="${IMAGE_PREFIX:-envoyproxy/envoy-build-}"
GCR_IMAGE_PREFIX=gcr.io/envoy-ci/
# Enable docker experimental
export DOCKER_CLI_EXPERIMENTAL=enabled
CONTAINER_SHA="$(git log -1 --pretty=format:"%H" .)"
CONTAINER_TAG="${CONTAINER_SHA}"
IMAGE_TAGS=()


ci_log_run () {
    if [[ -n "$CI" ]]; then
        echo "::group::${*}"
    fi
    "${@}"
    echo
    ci_log_run_end
}

ci_log_run_end () {
    if [[ -n "$CI" && -z "$LOG_CONTINUE" ]]; then
        echo "::endgroup::"
        unset LOG_CONTINUE
    fi
}

pull_image () {
    if [[ "$OS_DISTRO" == "debian" ]]; then
        # temp hack to get containers building
        container_name="envoy-build"
    else
        container_name="${IMAGE_PREFIX}${OS_DISTRO}"
    fi
    ci_log_run echo "Building ${container_name}:${CONTAINER_SHA}"
    container_url="https://index.docker.io/v1/repositories/${container_name}/tags/${CONTAINER_SHA}"
    if curl -sSLf "$container_url" &> /dev/null; then
        echo "${container_name}:${CONTAINER_SHA} exists."
        ci_log_run_end
        exit 0
    fi
    ci_log_run_end
}

pull_image

if [[ "${SOURCE_BRANCH}" == "refs/heads/main" ]]; then
    LOG_CONTINUE=1
    ci_log_run docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"
    if [[ "$OS_DISTRO" == "debian" ]]; then
        IMAGE_TAGS+=("envoyproxy/envoy-build:${CONTAINER_SHA}")
    else
        IMAGE_TAGS+=("${IMAGE_PREFIX}${OS_DISTRO}:${CONTAINER_SHA}")
    fi

    if [[ "${PUSH_GCR_IMAGE}" == "true" ]]; then
        echo ${GCP_SERVICE_ACCOUNT_KEY} | base64 --decode | gcloud auth activate-service-account --key-file=-
        gcloud auth configure-docker --quiet
        if [[ "${OS_DISTRO}" == "debian" ]]; then
            IMAGE_TAGS+=("${GCR_IMAGE_PREFIX}${GCR_IMAGE_NAME}:ci-${CONTAINER_SHA}${TAG_SUFFIX}")
        else
            IMAGE_TAGS+=("${GCR_IMAGE_PREFIX}${GCR_IMAGE_NAME}:${CONTAINER_SHA}${TAG_SUFFIX}")
        fi
    fi
    ci_log_run_end
fi

cd "${OS_FAMILY}" || exit 1

# Use distro-specific build script if available
if [[ "${OS_DISTRO}" == "debian" && -f "./debian_build.sh" ]]; then
    source "./debian_build.sh"
else
    source "./build.sh"
fi

ci_log_run docker images

if [[ "${#IMAGE_TAGS[@]}" -eq 0 ]]; then
    echo 'Ignoring PR branch for docker push.'
fi
