#!/bin/bash

set -e

function download_and_check () {
    local to=$1
    local url=$2
    local sha256=$3

    curl -fsSL --output "${to}" "${url}"
    echo "${sha256}  ${to}" | sha256sum --check
}


# buildifier
VERSION=2.2.1
download_and_check /usr/local/bin/buildifier https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildifier \
                   731a6a9bf8fca8a00a165cd5b3fbac9907a7cf422ec9c2f206b0a76c0a7e3d62
chmod +x /usr/local/bin/buildifier

# buildozer
VERSION=2.2.1
download_and_check /usr/local/bin/buildozer https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildozer \
                   5aa4f70f5f04599da2bb5b7e6a46af3e323a3a744c11d7802517d956909633ae
chmod +x /usr/local/bin/buildozer

# bazelisk
VERSION=1.3.0
download_and_check /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v${VERSION}/bazelisk-linux-amd64 \
                   98af93c6781156ff3dd36fa06ba6b6c0a529595abb02c569c99763203f3964cc
chmod +x /usr/local/bin/bazel
