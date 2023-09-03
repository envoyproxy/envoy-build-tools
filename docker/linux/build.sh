#!/bin/bash -e

set -o pipefail

UBUNTU_DOCKER_VARIANTS=("mobile")
IMAGE_TAGS=${IMAGE_TAGS:-}

# Setting environments for buildx tools
config_env() {
    # Install QEMU emulators
    docker run --rm --privileged tonistiigi/binfmt --install all

    # Remove older build instance
    docker buildx rm envoy-build-tools-builder || :
    docker buildx create --use --name envoy-build-tools-builder --platform "${BUILD_TOOLS_PLATFORMS}"
}

[[ -z "${OS_DISTRO}" ]] && OS_DISTRO="ubuntu"
[[ -z "${IMAGE_NAME}" ]] && IMAGE_NAME="envoyproxy/envoy-build-${OS_DISTRO}"

if [[ -z "${BUILD_TOOLS_PLATFORMS}" ]]; then
    if [[ "${OS_DISTRO}" == "ubuntu" ]]; then
        export BUILD_TOOLS_PLATFORMS=linux/arm64,linux/amd64
    else
        export BUILD_TOOLS_PLATFORMS=linux/amd64
    fi
fi

ci_log_run config_env

# TODO(phlax): add (json) build images config
build_and_push_variants () {
    if [[ "${OS_DISTRO}" != "ubuntu" ]]; then
        return
    fi
    local variant=""
    local push_arg=()
    if [[ -n "${IMAGE_TAGS}" ]]; then
        # Variants are only pushed to dockerhub currently, so if we are pushing images
        # just push the variants immediately.
        push_arg+=(--push)
    fi
    for variant in "${UBUNTU_DOCKER_VARIANTS[@]}"; do
        # Only build variants for linux/amd64
        ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_NAME}:${variant}-${CONTAINER_TAG}" --target "${variant}" --platform "linux/amd64" "${push_arg[@]}"
    done
}

ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_NAME}:${CONTAINER_TAG}" --target base --platform "${BUILD_TOOLS_PLATFORMS}"

if [[ -z "${NO_BUILD_VARIANTS}" ]]; then
    # variants are only pushed for the dockerhub image (not other `IMAGE_TAGS`)
    build_and_push_variants
fi
if [[ -n "${IMAGE_TAGS}" ]]; then
    for IMAGE_TAG in "${IMAGE_TAGS[@]}"; do
        ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_TAG}" --target base --platform "${BUILD_TOOLS_PLATFORMS}" --push
    done
fi

# Testing after push to save CI time because this invalidates arm64 cache
ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_NAME}:${CONTAINER_TAG}-amd64" --platform "linux/amd64" --load
ci_log_run docker run --rm -v "$(pwd)/docker/linux/test.sh":/test.sh "${IMAGE_NAME}:${CONTAINER_TAG}-amd64" true
