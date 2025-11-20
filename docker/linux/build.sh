#!/bin/bash -e

set -o pipefail

# Ubuntu-specific build configuration
UBUNTU_DOCKER_VARIANTS=("ci" "mobile" "test")
IMAGE_TAGS=${IMAGE_TAGS:-}


[[ -z "${OS_DISTRO}" ]] && OS_DISTRO="ubuntu"
[[ -z "${IMAGE_NAME}" ]] && IMAGE_NAME="envoyproxy/envoy-build-${OS_DISTRO}"

# Ubuntu uses multi-arch builds by default
if [[ -z "${BUILD_TOOLS_PLATFORMS}" ]]; then
    if [[ "${OS_DISTRO}" == "ubuntu" ]]; then
        export BUILD_TOOLS_PLATFORMS=linux/arm64,linux/amd64
    else
        export BUILD_TOOLS_PLATFORMS=linux/amd64
    fi
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

# Build Ubuntu variants with specific platform logic
# TODO(phlax): add (json) build images config
build_and_push_variants () {
    if [[ "${OS_DISTRO}" != "ubuntu" ]]; then
        return
    fi
    local variant="" platform push_arg
    for variant in "${UBUNTU_DOCKER_VARIANTS[@]}"; do
        push_arg=()
        if [[ "${SAVE_OCI}" == "true" ]]; then
            # Save to OCI format
            push_arg+=(--output "type=oci,dest=${OCI_OUTPUT_DIR}/${OS_DISTRO}-${variant}-${CONTAINER_TAG}${ARCH_SUFFIX}.tar")
        elif [[ -n "${IMAGE_TAGS}" && "$variant" != "test" ]]; then
            # Variants are only pushed to dockerhub currently, so if we are pushing images
            # just push the variants immediately.
            push_arg+=(--push)
        fi

        if [[ "$variant" == "test" || "$variant" == "ci" ]]; then
            platform="$BUILD_TOOLS_PLATFORMS"
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

# Default target for Ubuntu is 'full' (complete build environment)
# Build the full/main image first
if [[ "${SAVE_OCI}" == "true" ]]; then
    echo "Building OCI artifact to: ${OCI_OUTPUT_DIR}/${OS_DISTRO}-full-${CONTAINER_TAG}${ARCH_SUFFIX}.tar"
    ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_NAME}:${CONTAINER_TAG}${ARCH_SUFFIX}" --target full --platform "${BUILD_TOOLS_PLATFORMS}" \
        --output "type=oci,dest=${OCI_OUTPUT_DIR}/${OS_DISTRO}-full-${CONTAINER_TAG}${ARCH_SUFFIX}.tar"
else
    ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_NAME}:${CONTAINER_TAG}${ARCH_SUFFIX}" --target full --platform "${BUILD_TOOLS_PLATFORMS}"
fi

if [[ -z "${NO_BUILD_VARIANTS}" ]]; then
    # variants are only pushed for the dockerhub image (not other `IMAGE_TAGS`)
    build_and_push_variants
fi

if [[ "${SAVE_OCI}" != "true" ]] && [[ -n "${IMAGE_TAGS}" ]]; then
    for IMAGE_TAG in "${IMAGE_TAGS[@]}"; do
        if [[ "$IMAGE_TAG" == *"|"* ]]; then
            IFS="|" read -ra parts <<< "$IMAGE_TAG"
            ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${parts[0]}${ARCH_SUFFIX}" --target "${parts[1]}" --platform "${BUILD_TOOLS_PLATFORMS}" --push
        else
            ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_TAG}${ARCH_SUFFIX}" --target full --platform "${BUILD_TOOLS_PLATFORMS}" --push
        fi
    done
fi

if [[ "$LOAD_IMAGE" == "true" && "$BUILD_TOOLS_PLATFORMS" == *"linux/amd64"*  ]]; then
    # Testing after push to save CI time because this invalidates arm64 cache
    ci_log_run docker buildx build . -f "${OS_DISTRO}/Dockerfile" -t "${IMAGE_NAME}:${CONTAINER_TAG}${ARCH_SUFFIX}" --platform "linux/amd64" --load
fi
