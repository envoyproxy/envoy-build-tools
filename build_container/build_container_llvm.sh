#!/bin/bash -e

DEB_ARCH=amd64
if [[ "$(uname -m)" == "aarch64" ]]; then
    DEB_ARCH=arm64
    BUILDIFIER_SHA256SUM="$BUILDIFIER_SHA256SUM_ARM64"
    BUILDOZER_SHA256SUM="$BUILDOZER_SHA256SUM_ARM64"
    BAZELISK_SHA256SUM="$BAZELISK_SHA256SUM_ARM64"
fi

download_and_check () {
    local to=$1
    local url=$2
    local sha256=$3
    echo "Download: ${url} -> ${to}"
    curl -fsSL --output "${to}" "${url}"
    echo "${sha256}  ${to}" | sha256sum --check
}

install_llvm () {
    LLVM_RELEASE="clang+llvm-${LLVM_VERSION}-${LLVM_DISTRO}"
    download_and_check "${LLVM_RELEASE}.tar.xz" "${LLVM_DOWNLOAD_PREFIX}${LLVM_VERSION}/${LLVM_RELEASE}.tar.xz" "${LLVM_SHA256SUM}"
    mkdir /opt/llvm
    tar Jxf "${LLVM_RELEASE}.tar.xz" --strip-components=1 -C /opt/llvm
    chown -R root:root /opt/llvm
    rm "./${LLVM_RELEASE}.tar.xz"
    LLVM_HOST_TARGET="$(/opt/llvm/bin/llvm-config --host-target)"
    echo "/opt/llvm/lib/${LLVM_HOST_TARGET}" > /etc/ld.so.conf.d/llvm.conf
    ldconfig
}

install_libcxx () {
    local LLVM_USE_SANITIZER=$1
    local LIBCXX_PATH=$2
    mkdir "${LIBCXX_PATH}"
    pushd "${LIBCXX_PATH}"
    cmake -GNinja \
          -DLLVM_ENABLE_PROJECTS="libcxxabi;libcxx" \
          -DLLVM_USE_LINKER=lld \
          -DLLVM_USE_SANITIZER="${LLVM_USE_SANITIZER}" \
          -DCMAKE_BUILD_TYPE=RelWithDebInfo \
          -DCMAKE_C_COMPILER=clang \
          -DCMAKE_CXX_COMPILER=clang++ \
          -DCMAKE_INSTALL_PREFIX="/opt/libcxx_${LIBCXX_PATH}" \
          "../llvm-project-llvmorg-${LLVM_VERSION}/llvm"
    ninja install-cxx install-cxxabi
    if [[ ! -z "$(diff --exclude=__config_site -r /opt/libcxx_${LIBCXX_PATH}/include/c++ /opt/llvm/include/c++)" ]]; then
        echo "Different libc++ is installed";
        exit 1
    fi
    rm -rf "/opt/libcxx_${LIBCXX_PATH}/include"
    popd
}

install_llvm

git config --global --add safe.directory /source
mv ~/.gitconfig /etc/gitconfig

# Install sanitizer instrumented libc++, skipping for architectures other than x86_64 for now.
if [[ "$(uname -m)" != "x86_64" ]]; then
  mkdir /opt/libcxx_msan
  mkdir /opt/libcxx_tsan
  return 0
fi

export PATH="/opt/llvm/bin:${PATH}"

WORKDIR=$(mktemp -d)

pushd "${WORKDIR}"
curl -sSfL "https://github.com/llvm/llvm-project/archive/llvmorg-${LLVM_VERSION}.tar.gz" | tar zx
install_libcxx MemoryWithOrigins msan
install_libcxx Thread tsan
popd
