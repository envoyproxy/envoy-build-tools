#!/bin/bash
#The ppc64le is not supported by google-cloud-sdk. So ppc64le is temporary removed.

set -e

# To be enabled
# UBUNTU_DOCKER_VARIANTS=("mobile")
UBUNTU_DOCKER_VARIANTS=()

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

build_and_push_variants () {
    local variant
    if [[ "${OS_DISTRO}" != "ubuntu" ]]; then
        return
    fi
    for variant in "${UBUNTU_DOCKER_VARIANTS[@]}"; do
        ci_log_run docker buildx build . -f "Dockerfile-${OS_DISTRO}" -t "${IMAGE_NAME}-${variant}:${CONTAINER_TAG}" --target "${variant}" --platform "${BUILD_TOOLS_PLATFORMS}"
    done
}

ci_log_run docker buildx build . -f "Dockerfile-${OS_DISTRO}" -t "${IMAGE_NAME}:${CONTAINER_TAG}" --target base --platform "${BUILD_TOOLS_PLATFORMS}"

# variants are only pushed for the dockerhub image (not other `IMAGE_TAGS`)
build_and_push_variants


for IMAGE_TAG in "${IMAGE_TAGS[@]}"; do
    ci_log_run docker buildx build . -f "Dockerfile-${OS_DISTRO}" -t "${IMAGE_TAG}" --target base --platform "${BUILD_TOOLS_PLATFORMS}" --push
done

# Testing after push to save CI time because this invalidates arm64 cache
ci_log_run docker buildx build . -f "Dockerfile-${OS_DISTRO}" -t "${IMAGE_NAME}:${CONTAINER_TAG}-amd64" --platform "linux/amd64" --load
echo "Test linux container: ${IMAGE_NAME}:${CONTAINER_TAG}"
docker run --rm -v "$(pwd)/docker_test_linux.sh":/test.sh "${IMAGE_NAME}:${CONTAINER_TAG}-amd64" true
