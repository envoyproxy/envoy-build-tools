#!/bin/bash

set -e

export RBE_AUTOCONF_ROOT=$(bazel info workspace)

CONTAINER_TAG=$(git log -1 --pretty=format:"%H" "${RBE_AUTOCONF_ROOT}/build_container")

DOCKER_IMAGE=gcr.io/envoy-ci/envoy-build:${CONTAINER_TAG}
if docker pull ${DOCKER_IMAGE}; then
  echo "Image is not built, skip..."
fi

DOCKER_REPODIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' ${DOCKER_IMAGE} | grep -oE 'sha256:[0-9a-f]{64}')

sed -i -E "s#_ENVOY_BUILD_IMAGE_DIGEST = \"sha256:[0-9a-f]{64}\"#_ENVOY_BUILD_IMAGE_DIGEST = \"${DOCKER_REPODIGEST}\"#" toolchains/rbe_toolchains_config.bzl

mkdir -p "${RBE_AUTOCONF_ROOT}"/toolchains/configs
rm -rf "${RBE_AUTOCONF_ROOT}"/toolchains/configs/*
cp -vf "${RBE_AUTOCONF_ROOT}/toolchains/empty.bzl" "${RBE_AUTOCONF_ROOT}/toolchains/configs/versions.bzl"

# Bazel query is the right command so bazel won't fail itself.
bazel query ${BAZEL_QUERY_OPTIONS} "@rbe_ubuntu_clang_gen//..."
bazel query ${BAZEL_QUERY_OPTIONS} "@rbe_ubuntu_clang_libcxx_gen//..."
bazel query ${BAZEL_QUERY_OPTIONS} "@rbe_ubuntu_gcc_gen//..."

git add "${RBE_AUTOCONF_ROOT}"/toolchains/configs
if [[ -z "$(git diff HEAD --name-only)" ]]; then
  echo "No toolchain changes."
  exit 0
fi

COMMIT_MSG="Regenerate toolchains from $(git rev-parse HEAD)

$(git log --format=%B -n 1)"
git commit -m "${COMMIT_MSG}"
