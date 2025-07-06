#!/bin/bash -e

set -o pipefail

# Debian-specific build configuration
DEBIAN_DOCKER_VARIANTS=("worker" "ci" "devtools" "docker" "llvm" "mobile" "test")
IMAGE_TAGS=${IMAGE_TAGS:-}
OS_DISTRO="debian"

[[ -z "${IMAGE_NAME}" ]] && IMAGE_NAME="envoyproxy/envoy-build"

# Debian uses multi-arch builds
if [[ -z "${BUILD_TOOLS_PLATFORMS}" ]]; then
    export BUILD_TOOLS_PLATFORMS=linux/arm64,linux/amd64
fi

HOST_ARCH="$(uname -m)"
MULTI_ARCH=
CROSS_ARCH=

if [[ "$BUILD_TOOLS_PLATFORMS" == *","* ]]; then
    MULTI_ARCH=true
else
    ARCH_NAME="$(echo "${BUILD_TOOLS_PLATFORMS}" | cut -d/ -f2)"
    ARCH_SUFFIX="-$ARCH_NAME"
    if [[ "$HOST_ARCH" == "x86_64" && "$BUILD_TOOLS_PLATFORMS" != "linux/amd64" ]]; then
        CROSS_ARCH=true
    elif [[ "$HOST_ARCH" == "aarch64" && "$BUILD_TOOLS_PLATFORMS" != "linux/arm64" ]]; then
        CROSS_ARCH=true
    fi
fi

# Setting environments for buildx tools
config_env() {
    if [[ -n "$MULTI_ARCH" || -n "$CROSS_ARCH" ]]; then
        # Install QEMU emulators
        docker run --rm --privileged tonistiigi/binfmt --install all
    fi

    # Remove older build instance
    docker buildx rm envoy-build-tools-builder &> /dev/null || :
    docker buildx create --use --name envoy-build-tools-builder --platform "${BUILD_TOOLS_PLATFORMS}"
}

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

        # Platform logic: worker, ci, docker and test get multi-arch, others get amd64 only
        if [[ "$variant" == "test" || "$variant" == "ci" || "$variant" == "docker" || "$variant" == "worker" ]]; then
            platform="${BUILD_TOOLS_PLATFORMS}"
        elif [[ "$BUILD_TOOLS_PLATFORMS" == *"linux/amd64"* ]]; then
            # devtools and mobile are amd64 only (matching original behavior for full/mobile)
            platform="linux/amd64"
        else
            continue
        fi
        ci_log_run docker buildx build . \
                   -f "${OS_DISTRO}/Dockerfile" \
                   -t "${IMAGE_NAME}:${variant}-${CONTAINER_TAG}${ARCH_SUFFIX}" \
                   --target "${variant}" \
                   --platform "$platform" \
                   "${push_arg[@]}"
    done
}


ci_log_run config_env

# Default target for Debian is 'ci' (includes bazel for builds)
ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_NAME}:${CONTAINER_TAG}${ARCH_SUFFIX}" --target ci --platform "${BUILD_TOOLS_PLATFORMS}"

if [[ -z "${NO_BUILD_VARIANTS}" ]]; then
    # variants are only pushed for the dockerhub image (not other `IMAGE_TAGS`)
    build_and_push_variants
fi

if [[ -n "${IMAGE_TAGS}" ]]; then
    for IMAGE_TAG in "${IMAGE_TAGS[@]}"; do
        if [[ "$IMAGE_TAG" == *"|"* ]]; then
            IFS="|" read -ra parts <<< "$IMAGE_TAG"
            ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${parts[0]}${ARCH_SUFFIX}" --target "${parts[1]}" --platform "${BUILD_TOOLS_PLATFORMS}" --push
        else
            # Default target for Debian is 'ci' (includes bazel for builds)
            ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_TAG}${ARCH_SUFFIX}" --target ci --platform "${BUILD_TOOLS_PLATFORMS}" --push
        fi
    done
fi

if [[ "$LOAD_IMAGE" == "true" && "$BUILD_TOOLS_PLATFORMS" == *"linux/amd64"*  ]]; then
    ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_NAME}:${CONTAINER_TAG}${ARCH_SUFFIX}" --target ci --platform "linux/amd64" --load
fi
