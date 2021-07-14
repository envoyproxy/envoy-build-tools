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
  git pull origin refs/heads/main --ff-only
fi

rm -rf "${RBE_AUTOCONF_ROOT}/toolchains/configs/${OS_FAMILY}"
mkdir -p "${RBE_AUTOCONF_ROOT}/toolchains/configs/${OS_FAMILY}"

case ${OS_FAMILY} in
  linux)
    TOOLCHAIN_LIST="clang clang_libcxx gcc"
    BAZELRC_TEMPLATE=${RBE_AUTOCONF_ROOT}/toolchains/linux.latest.bazelrc
    ;;
  windows)
    TOOLCHAIN_LIST="msvc-cl clang-cl"
    BAZELRC_TEMPLATE=${RBE_AUTOCONF_ROOT}/toolchains/windows.latest.bazelrc
    ;;
esac

BAZELRC_DEST=${RBE_AUTOCONF_ROOT}/toolchains/configs/${OS_FAMILY}/.latest.bazelrc

# Fetch external dependencies
bazel fetch :all

# Build utility for generating RBE config
RBE_CONFIG_GEN_DIR=$(bazel info output_base)/external/bazel_toolchains/cmd/rbe_configs_gen
(cd "${RBE_CONFIG_GEN_DIR}" && go build)

# Keep bazel versions here at most two: current main version, next version
for BAZEL_VERSION in "3.7.2" "4.1.0"; do
  for TOOLCHAIN in ${TOOLCHAIN_LIST}; do
    "${RBE_CONFIG_GEN_DIR}/rbe_configs_gen" -exec_os ${OS_FAMILY} -generate_java_configs=false -generate_cpp_configs -output_src_root "${RBE_AUTOCONF_ROOT}" -output_config_path toolchains/configs/${OS_FAMILY}/${TOOLCHAIN}/bazel_${BAZEL_VERSION} -target_os ${OS_FAMILY} -bazel_version ${BAZEL_VERSION} -toolchain_container ${DOCKER_IMAGE} -cpp_env_json "${RBE_AUTOCONF_ROOT}/toolchains/${TOOLCHAIN}.env.json"
  done
done

cp "${BAZELRC_TEMPLATE}" "${BAZELRC_DEST}"
sed -i -E "s#BAZEL_VERSION#${BAZEL_VERSION}#g" "${BAZELRC_DEST}"

chmod -R 755 "${RBE_AUTOCONF_ROOT}/toolchains/configs/${OS_FAMILY}"

git add "${RBE_AUTOCONF_ROOT}/toolchains/configs/${OS_FAMILY}"

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
