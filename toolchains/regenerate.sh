#!/bin/bash

set -e

export RBE_AUTOCONF_ROOT=$(bazel info workspace)

CONTAINER_TAG=$(git log -1 --pretty=format:"%H" "${RBE_AUTOCONF_ROOT}/build_container")

DOCKER_IMAGE="gcr.io/envoy-ci/${GCR_IMAGE_NAME}:${CONTAINER_TAG}"
if ! docker pull ${DOCKER_IMAGE}; then
  echo "Image is not built, skip..."
  exit 0
fi

# If we are committing changes, pull before modifying to ensure no conflicts
if [[ "true" == "${COMMIT_TOOLCHAINS}" ]]; then
  git pull origin refs/heads/master --ff-only
fi

UCASE_OS_FAMILY=`echo ${OS_FAMILY} | tr "[:lower:]" "[:upper:]"`
DOCKER_REPODIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' ${DOCKER_IMAGE} | grep -oE 'sha256:[0-9a-f]{64}')

sed -i -E "s#(_ENVOY_BUILD_IMAGE_DIGEST_${UCASE_OS_FAMILY} =) \"sha256:[0-9a-f]{64}\"#\1 \"${DOCKER_REPODIGEST}\"#" toolchains/rbe_toolchains_config.bzl
sed -i -E "s#(_ENVOY_BUILD_IMAGE_TAG =) \"[0-9a-f]{40}\"#\1 \"${CONTAINER_TAG}\"#" toolchains/rbe_toolchains_config.bzl

mkdir -p "${RBE_AUTOCONF_ROOT}/toolchains/configs/${OS_FAMILY}"
rm -rf "${RBE_AUTOCONF_ROOT}/toolchains/configs/${OS_FAMILY}/*"
cp -vf "${RBE_AUTOCONF_ROOT}/toolchains/empty.bzl" "${RBE_AUTOCONF_ROOT}/toolchains/configs/${OS_FAMILY}/versions.bzl"

case ${OS_FAMILY} in
  linux)
    RBE_BAZEL_TARGET_LIST="@rbe_ubuntu_clang_gen//... @rbe_ubuntu_clang_libcxx_gen//... @rbe_ubuntu_gcc_gen//..."
    ;;
  windows)
    RBE_BAZEL_TARGET_LIST="@rbe_windows_msvc_cl_gen//..."
    ;;
esac

# Bazel query is the right command so bazel won't fail itself.
# Keep bazel versions here at most two: current master version, next version
for BAZEL_VERSION in "3.0.0" "3.1.0"; do
  for RBE_BAZEL_TARGET in ${RBE_BAZEL_TARGET_LIST}; do
    USE_BAZEL_VERSION="${BAZEL_VERSION}" bazel query ${BAZEL_QUERY_OPTIONS} ${RBE_BAZEL_TARGET}
  done
done

git add "${RBE_AUTOCONF_ROOT}/toolchains/configs/${OS_FAMILY}"
git add "${RBE_AUTOCONF_ROOT}/toolchains/rbe_toolchains_config.bzl"

if [[ -z "$(git diff HEAD --name-only)" ]]; then
  echo "No toolchain changes."
  exit 0
fi

if [[ "true" == "${COMMIT_TOOLCHAINS}" ]]; then
  COMMIT_MSG="Regenerate ${OS_FAMILY} toolchains from $(git rev-parse HEAD)

  [skip ci]
  $(git log --format=%B -n 1)"

  git config user.name "envoy-build-tools(Azure Pipelines)"
  git config user.email envoy-build-tools@users.noreply.github.com

  git commit -m "${COMMIT_MSG}"

  if [[ "${SOURCE_BRANCH}" =~ ^refs/heads/.* ]]; then
    git push git@github.com:envoyproxy/envoy-build-tools.git "HEAD:${SOURCE_BRANCH}"
  fi
fi
