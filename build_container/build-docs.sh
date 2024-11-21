#!/bin/bash -e

export ENVOY_REPO=(${ENVOY_REPO:-https://github.com/envoyproxy/envoy})

fetch_repo () {
    if [ -d "$ENVOY_SRCDIR" ]; then
        echo "Building docs from mounted source"
    elif [ -n "${ENVOY_REPO}" ]; then
        echo "Building docs from clone: ${ENVOY_REPO[@]}"
        mkdir -p $(dirname "$ENVOY_SRCDIR")
        cd $(dirname "$ENVOY_SRCDIR")
        git clone "${ENVOY_REPO[@]}"
    fi
    if [ ! -d "$ENVOY_SRCDIR" ]; then
        echo "Either mount an envoy source dir to /source/envoy or set ENVOY_REPO to a valid envoy repository"
        exit 1
    fi
}

fetch_repo
cd "$ENVOY_SRCDIR"
./docs/build.sh
cp -a generated/docs/* /docs
