#!/bin/bash -e

set -o pipefail

# Debian-specific build configuration
DEBIAN_DOCKER_VARIANTS=("ci" "devel" "mobile" "test")
IMAGE_TAGS=${IMAGE_TAGS:-}
OS_DISTRO="debian"

# Setting environments for buildx tools
config_env() {
    # Install QEMU emulators
    docker run --rm --privileged tonistiigi/binfmt --install all

    # Remove older build instance
    docker buildx rm envoy-build-tools-builder &> /dev/null || :
    docker buildx create --use --name envoy-build-tools-builder --platform "${BUILD_TOOLS_PLATFORMS}"
}

[[ -z "${IMAGE_NAME}" ]] && IMAGE_NAME="envoyproxy/envoy-build"

# Debian uses multi-arch builds
if [[ -z "${BUILD_TOOLS_PLATFORMS}" ]]; then
    export BUILD_TOOLS_PLATFORMS=linux/arm64,linux/amd64
fi

ci_log_run config_env

# Build Debian variants with specific platform logic
build_and_push_variants () {
    local variant="" platform push_arg
    
    for variant in "${DEBIAN_DOCKER_VARIANTS[@]}"; do
        push_arg=()
        if [[ -n "${IMAGE_TAGS}" && "$variant" != "test" ]]; then
            # Variants are only pushed to dockerhub currently, so if we are pushing images
            # just push the variants immediately.
            push_arg+=(--push)
        fi

        # Platform logic: ci and test get multi-arch, others get amd64 only
        if [[ "$variant" == "test" || "$variant" == "ci" ]]; then
            platform="linux/amd64,linux/arm64"
        else
            # devel and mobile are amd64 only (matching original behavior for full/mobile)
            platform="linux/amd64"
        fi
        
        ci_log_run docker buildx build . \
                   -f "${OS_DISTRO}/Dockerfile" \
                   -t "${IMAGE_NAME}:${variant}-${CONTAINER_TAG}" \
                   --target "${variant}" \
                   --platform "$platform" \
                   "${push_arg[@]}"
    done
}

# Default target for Debian is 'ci' (not 'full' like Ubuntu)
ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_NAME}:${CONTAINER_TAG}" --target ci --platform "${BUILD_TOOLS_PLATFORMS}"

if [[ -z "${NO_BUILD_VARIANTS}" ]]; then
    # variants are only pushed for the dockerhub image (not other `IMAGE_TAGS`)
    build_and_push_variants
fi

if [[ -n "${IMAGE_TAGS}" ]]; then
    for IMAGE_TAG in "${IMAGE_TAGS[@]}"; do
        if [[ "$IMAGE_TAG" == *"|"* ]]; then
            IFS="|" read -ra parts <<< "$IMAGE_TAG"
            ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${parts[0]}" --target "${parts[1]}" --platform "${BUILD_TOOLS_PLATFORMS}" --push
        else
            # Default target for Debian is 'ci'
            ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_TAG}" --target ci --platform "${BUILD_TOOLS_PLATFORMS}" --push
        fi
    done
fi

if [[ "$LOAD_IMAGE" == "true" ]]; then
    # Testing after push to save CI time because this invalidates arm64 cache
    ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_NAME}:${CONTAINER_TAG}" --target ci --platform "linux/amd64" --load
fi