#!/usr/bin/env bash

set -eu -o pipefail

export GOARCH=$(dpkg --print-architecture)

BUILD_TMP="$(mktemp -d)"
trap "chmod +w -R ${BUILD_TMP} && rm -rf ${BUILD_TMP}" EXIT

cd "${BUILD_TMP}"

curl -fsSL https://golang.org/dl/go1.14.5.linux-${GOARCH}.tar.gz | tar zx
export GOPATH="${BUILD_TMP}/gopath"

git clone https://github.com/buchgr/bazel-remote
cd bazel-remote
PATH="${BUILD_TMP}/go/bin:${PATH}" ./linux-build.sh
sudo cp ./bazel-remote /usr/local/bin/bazel-remote
