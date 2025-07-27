#!/bin/bash

# Do not ever set -x here, it is a security hazard as it will place the credentials below in the
# CI logs.
set -e

IMAGE_PREFIX="${IMAGE_PREFIX:-envoyproxy/envoy-build-}"
GCR_IMAGE_PREFIX=gcr.io/envoy-ci/
# Enable docker experimental
export DOCKER_CLI_EXPERIMENTAL=enabled
CONTAINER_SHA="${CONTAINER_SHA:-$(git log -1 --pretty=format:"%H" .)}"
CONTAINER_TAG="${CONTAINER_SHA}"
IMAGE_TAGS=()
OCI_OUTPUT_DIR="oci-output"


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

# Skip image check when saving to OCI artifacts
if [[ "${SAVE_OCI}" != "true" ]]; then
    pull_image
fi

# For OCI artifact saving, we always need to determine the image tags
# but we won't push them - we'll save them to local files
if [[ "${SAVE_OCI}" == "true" ]] || [[ "${SOURCE_BRANCH}" == "refs/heads/main" ]]; then
    if [[ "$OS_DISTRO" == "debian" ]]; then
        BASE_IMAGE_NAME="envoyproxy/envoy-build"
    else
        BASE_IMAGE_NAME="${IMAGE_PREFIX}${OS_DISTRO}"
    fi

fi

# Create OCI output directory before changing to OS_FAMILY dir
if [[ "${SAVE_OCI}" == "true" ]]; then
    echo "Creating OCI output directory: ${OCI_OUTPUT_DIR}"
    mkdir -p "${OCI_OUTPUT_DIR}"
fi

cd "${OS_FAMILY}" || exit 1

# Adjust OCI output dir path since we're now in the OS_FAMILY directory
if [[ "${SAVE_OCI}" == "true" ]]; then
    OCI_OUTPUT_DIR="../oci-output"
fi

# Export variables for build scripts
export SAVE_OCI
export OCI_OUTPUT_DIR
export BASE_IMAGE_NAME

# Use distro-specific build script if available
if [[ "${OS_DISTRO}" == "debian" && -f "./debian_build.sh" ]]; then
    source "./debian_build.sh"
else
    source "./build.sh"
fi

ci_log_run docker images

if [[ "${SAVE_OCI}" != "true" ]] && [[ "${#IMAGE_TAGS[@]}" -eq 0 ]]; then
    echo 'Ignoring PR branch for docker push.'
fi
