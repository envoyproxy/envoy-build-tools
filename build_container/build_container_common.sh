#!/bin/bash -e

DEB_ARCH=amd64
if [[ "$(uname -m)" == "aarch64" ]]; then
    DEB_ARCH=arm64
    BUILDIFIER_SHA256SUM="$BUILDIFIER_SHA256SUM_ARM64"
    BUILDOZER_SHA256SUM="$BUILDOZER_SHA256SUM_ARM64"
    BAZELISK_SHA256SUM="$BAZELISK_SHA256SUM_ARM64"
fi


function download_and_check () {
    local to=$1
    local url=$2
    local sha256=$3
    echo "Download: ${url} -> ${to}"
    curl -fsSL --output "${to}" "${url}"
    echo "${sha256}  ${to}" | sha256sum --check
}

function install_gn(){
    # Install gn tools which will be used for building wee8
    wget -O gntool.zip "https://chrome-infra-packages.appspot.com/dl/gn/gn/linux-${DEB_ARCH}/+/latest"
    unzip gntool.zip -d gntool
    cp gntool/gn /usr/local/bin/gn
    chmod +x /usr/local/bin/gn
    rm -rf gntool*
}

# buildifier
download_and_check \
    /usr/local/bin/buildifier \
    "https://github.com/bazelbuild/buildtools/releases/download/${BUILD_TOOLS_VERSION}/buildifier-linux-${DEB_ARCH}" \
    "${BUILDIFIER_SHA256SUM}"
chmod +x /usr/local/bin/buildifier

# buildozer
download_and_check \
    /usr/local/bin/buildozer \
    "https://github.com/bazelbuild/buildtools/releases/download/${BUILD_TOOLS_VERSION}/buildozer-linux-${DEB_ARCH}" \
    "${BUILDOZER_SHA256SUM}"
chmod +x /usr/local/bin/buildozer

# bazelisk
download_and_check \
    /usr/local/bin/bazel \
    "https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-${DEB_ARCH}" \
    "${BAZELISK_SHA256SUM}"
chmod +x /usr/local/bin/bazel

LLVM_RELEASE="clang+llvm-${LLVM_VERSION}-${LLVM_DISTRO}"
LLVM_DOWNLOAD_PREFIX=${LLVM_DOWNLOAD_PREFIX:-https://github.com/llvm/llvm-project/releases/download/llvmorg-}
download_and_check "${LLVM_RELEASE}.tar.xz" "${LLVM_DOWNLOAD_PREFIX}${LLVM_VERSION}/${LLVM_RELEASE}.tar.xz" "${LLVM_SHA256SUM}"
mkdir /opt/llvm
tar Jxf "${LLVM_RELEASE}.tar.xz" --strip-components=1 -C /opt/llvm
chown -R root:root /opt/llvm
rm "./${LLVM_RELEASE}.tar.xz"
LLVM_HOST_TARGET="$(/opt/llvm/bin/llvm-config --host-target)"
echo "/opt/llvm/lib/${LLVM_HOST_TARGET}" > /etc/ld.so.conf.d/llvm.conf
ldconfig

if [[ -n "$CLANG_TOOLS_SHA256SUM" ]]; then
    # Pick `run-clang-tidy.py` from `clang-tools-extra` and place in filepath expected by Envoy CI.
    # Only required for more recent LLVM/Clang versions
    ENVOY_CLANG_TIDY_PATH=/opt/llvm/share/clang/run-clang-tidy.py
    CLANG_TOOLS_SRC="clang-tools-extra-${LLVM_VERSION}.src"
    CLANG_TOOLS_TARBALL="${CLANG_TOOLS_SRC}.tar.xz"
    download_and_check "./${CLANG_TOOLS_TARBALL}" "${LLVM_DOWNLOAD_PREFIX}${LLVM_VERSION}/${CLANG_TOOLS_TARBALL}" "$CLANG_TOOLS_SHA256SUM"
    tar JxfO "./${CLANG_TOOLS_TARBALL}" "${CLANG_TOOLS_SRC}/clang-tidy/tool/run-clang-tidy.py" > "$ENVOY_CLANG_TIDY_PATH"
    rm "./${CLANG_TOOLS_TARBALL}"
fi

# Install gn tools.
install_gn

# Install lcov
LCOV_VERSION=1.15
download_and_check lcov-${LCOV_VERSION}.tar.gz https://github.com/linux-test-project/lcov/releases/download/v${LCOV_VERSION}/lcov-${LCOV_VERSION}.tar.gz \
  c1cda2fa33bec9aa2c2c73c87226cfe97de0831887176b45ee523c5e30f8053a
tar zxf lcov-${LCOV_VERSION}.tar.gz
make -C lcov-${LCOV_VERSION} install
rm -rf "lcov-${LCOV_VERSION}" "./lcov-${LCOV_VERSION}.tar.gz"

git config --global --add safe.directory /source
mv ~/.gitconfig /etc/gitconfig

# Install sanitizer instrumented libc++, skipping for architectures other than x86_64 for now.
if [[ "$(uname -m)" != "x86_64" ]]; then
  return 0
fi

export PATH="/opt/llvm/bin:${PATH}"

WORKDIR=$(mktemp -d)
function cleanup {
  rm -rf "${WORKDIR}"
}

trap cleanup EXIT
pushd "${WORKDIR}"
curl -sSfL "https://github.com/llvm/llvm-project/archive/llvmorg-${LLVM_VERSION}.tar.gz" | tar zx

function install_libcxx() {
  local LLVM_USE_SANITIZER=$1
  local LIBCXX_PATH=$2

  mkdir "${LIBCXX_PATH}"
  pushd "${LIBCXX_PATH}"

  cmake -GNinja -DLLVM_ENABLE_PROJECTS="libcxxabi;libcxx" -DLLVM_USE_LINKER=lld -DLLVM_USE_SANITIZER=${LLVM_USE_SANITIZER} -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_INSTALL_PREFIX="/opt/libcxx_${LIBCXX_PATH}" "../llvm-project-llvmorg-${LLVM_VERSION}/llvm"
  ninja install-cxx install-cxxabi

  if [[ ! -z "$(diff --exclude=__config_site -r /opt/libcxx_${LIBCXX_PATH}/include/c++ /opt/llvm/include/c++)" ]]; then
    echo "Different libc++ is installed";
    exit 1
  fi

  rm -rf "/opt/libcxx_${LIBCXX_PATH}/include"

  popd
}

install_libcxx MemoryWithOrigins msan
install_libcxx Thread tsan

popd
