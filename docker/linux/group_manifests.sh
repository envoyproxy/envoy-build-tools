#!/usr/bin/env bash

set -eo pipefail

IMAGE_REPOS=("envoyproxy/envoy-build" "envoyproxy/envoy-build-ubuntu")

if [[ -z "$TAG_SHA" ]]; then
    TAG_SHA="$(git log -1 --pretty=format:"%H" .)"
fi

VARIANTS=(ci worker devtools mobile test foobar)
ARCHES=(amd64 arm64)

exists() {
    docker manifest inspect "$1" >/dev/null 2>&1
}

append_variant() {
    local repo=$1
    local variant=$2
    local arch=$3
    local flags

    tag="${repo}:${variant}-${TAG_SHA}-${arch}"
    if ! exists "$tag"; then
        return
    fi
    echo "--append $tag"
}

for repo in "${IMAGE_REPOS[@]}"; do
    for variant in "${VARIANTS[@]}"; do
        vflags=()
        for arch in "${ARCHES[@]}"; do
            while read -r flag tag; do
                vflags+=("$flag" "$tag")
            done < <(append_variant "$repo" "$variant" "$arch")
        done
        docker buildx imagetools create --tag "${repo}:${variant}-${TAG_SHA}" "${vflags[@]}"
    done
done
