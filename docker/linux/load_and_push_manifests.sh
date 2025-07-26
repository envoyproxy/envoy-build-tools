#!/usr/bin/env bash

set -eo pipefail

# This script loads OCI artifacts and creates/pushes multi-arch manifests
# It creates ONLY multi-arch manifest tags, no individual architecture tags

OCI_IMAGES_PATH="${OCI_IMAGES_PATH:-./oci-images}"
TAG_SHA="${TAG_SHA:-$(git log -1 --pretty=format:"%H" ./docker)}"
GCR_IMAGE_PREFIX="gcr.io/envoy-ci/"
GCR_IMAGE_NAME="${GCR_IMAGE_NAME:-envoy-build}"
DRY_RUN="${DRY_RUN:-false}"

declare -A REPO_VARIANTS=(
    ["envoyproxy/envoy-build"]="ci worker devtools docker llvm mobile test"
    ["envoyproxy/envoy-build-ubuntu"]="ci mobile test full"
)

ARCHES=(amd64 arm64)

create_and_push_manifest() {
    local distro="$1"
    local variant="$2"
    local repo="$3"
    local manifest_tag="${repo}:${variant}-${TAG_SHA}"

    # Create temporary OCI directory for combined manifest
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # Check and copy each architecture to the temp OCI directory
    local found_any=false
    for arch in "${ARCHES[@]}"; do
        if [[ "$distro" == "debian" ]]; then
            oci_file="${OCI_IMAGES_PATH}/oci-debian-${arch}/debian-${variant}-${TAG_SHA}-${arch}.tar"
        else
            oci_file="${OCI_IMAGES_PATH}/oci-ubuntu-${arch}/ubuntu-${variant}-${TAG_SHA}-${arch}.tar"
        fi

        if [[ -f "$oci_file" ]]; then
            if [[ "$DRY_RUN" != "true" ]]; then
                echo "  Adding $arch architecture"
                skopeo copy --override-arch "$arch" --override-os linux \
                    "oci-archive:$oci_file" \
                    "oci:$temp_dir:$arch"
            fi
            found_any=true
        fi
    done

    if [[ "$found_any" != "true" ]]; then
        return
    fi

    echo "Processing $distro/$variant..."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would create and push manifest: $manifest_tag"
        for arch in "${ARCHES[@]}"; do
            if [[ "$distro" == "debian" ]]; then
                oci_file="${OCI_IMAGES_PATH}/oci-debian-${arch}/debian-${variant}-${TAG_SHA}-${arch}.tar"
            else
                oci_file="${OCI_IMAGES_PATH}/oci-ubuntu-${arch}/ubuntu-${variant}-${TAG_SHA}-${arch}.tar"
            fi
            if [[ -f "$oci_file" ]]; then
                echo "[DRY RUN]   - Would include $arch architecture"
            fi
        done
        # Show additional SHA-only tags
        if [[ "$distro" == "ubuntu" && "$variant" == "full" ]]; then
            echo "[DRY RUN] Would also push as: ${repo}:${TAG_SHA}"
        elif [[ "$distro" == "debian" && "$variant" == "ci" ]]; then
            echo "[DRY RUN] Would also push as: ${repo}:${TAG_SHA}"
        fi
    else
        # Push all architectures as a single manifest list
        echo "Pushing manifest list: $manifest_tag"
        skopeo copy --all "oci:$temp_dir" "docker://$manifest_tag"

        # Also push with just SHA for specific variants
        if [[ "$distro" == "ubuntu" && "$variant" == "full" ]]; then
            echo "Pushing Ubuntu full as: ${repo}:${TAG_SHA}"
            skopeo copy --all "oci:$temp_dir" "docker://${repo}:${TAG_SHA}"
        elif [[ "$distro" == "debian" && "$variant" == "ci" ]]; then
            echo "Pushing Debian ci as: ${repo}:${TAG_SHA}"
            skopeo copy --all "oci:$temp_dir" "docker://${repo}:${TAG_SHA}"
        fi
    fi

    # Also create GCR tags if enabled
    if [[ "${PUSH_GCR_IMAGE}" == "true" ]]; then
        create_gcr_tags "$distro" "$variant" "$manifest_tag"
    fi
}

create_gcr_tags() {
    local distro="$1"
    local variant="$2"
    local source_tag="$3"

    # Only push Ubuntu full image to GCR (with no prefix, just SHA)
    if [[ "$distro" != "ubuntu" || "$variant" != "full" ]]; then
        return
    fi

    local gcr_tag="${GCR_IMAGE_PREFIX}${GCR_IMAGE_NAME}:${TAG_SHA}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would copy manifest to GCR: $source_tag -> $gcr_tag"
    else
        echo "Copying manifest to GCR: $gcr_tag"
        skopeo copy --all "docker://$source_tag" "docker://$gcr_tag"
    fi
}

if [[ "$DRY_RUN" == "true" ]]; then
    echo "Starting manifest creation from OCI artifacts in DRY RUN mode..."
    echo "No images will be pushed to registries."
else
    echo "Starting manifest creation from OCI artifacts..."
fi

if ! command -v skopeo &> /dev/null; then
    echo "ERROR: skopeo is not installed. Please install skopeo to use this script."
    exit 1
fi
skopeo --version

echo "Processing Debian images..."
for variant in ${REPO_VARIANTS["envoyproxy/envoy-build"]}; do
    create_and_push_manifest "debian" "$variant" "envoyproxy/envoy-build"
done

echo "Processing Ubuntu images..."
for variant in ${REPO_VARIANTS["envoyproxy/envoy-build-ubuntu"]}; do
    create_and_push_manifest "ubuntu" "$variant" "envoyproxy/envoy-build-ubuntu"
done

echo "Manifest creation complete!"
