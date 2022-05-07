#!/bin/bash
#The ppc64le is not supported by google-cloud-sdk. So ppc64le is temporary removed.

set -e

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

BUILDX_OPTIONS=()
if is_gha; then
  BUILDX_OPTIONS+=("--cache-to=type=gha,mode=max" "--cache-from=type=gha")
fi

ci_log_run config_env

ci_log_run docker buildx build "${BUILDX_OPTIONS[@]}" . -f "Dockerfile-${OS_DISTRO}" -t "${IMAGE_NAME}:${CONTAINER_TAG}" --platform "${BUILD_TOOLS_PLATFORMS}"

ci_log_run docker buildx build "${BUILDX_OPTIONS[@]}" . -f "Dockerfile-${OS_DISTRO}" -t "${IMAGE_NAME}:${CONTAINER_TAG}-amd64" --platform "linux/amd64" --load
echo "Test linux container: ${IMAGE_NAME}:${CONTAINER_TAG}"
ci_log_run docker run --rm -v "$(pwd)/docker_test_linux.sh":/test.sh "${IMAGE_NAME}:${CONTAINER_TAG}-amd64" true

ci_log_run docker buildx build "${BUILDX_OPTIONS[@]}" . -f "Dockerfile-${OS_DISTRO}" -t "${IMAGE_NAME}-2:${CONTAINER_TAG}" --platform "${BUILD_TOOLS_PLATFORMS}"
ci_log_run docker buildx build "${BUILDX_OPTIONS[@]}" . -f "Dockerfile-${OS_DISTRO}" -t "${IMAGE_NAME}-3:${CONTAINER_TAG}" --platform "${BUILD_TOOLS_PLATFORMS}"

for IMAGE_TAG in "${IMAGE_TAGS[@]}"; do
  ci_log_run docker buildx build . -f "Dockerfile-${OS_DISTRO}" -t "${IMAGE_TAG}" --platform "${BUILD_TOOLS_PLATFORMS}" --push
done
