#!/bin/bash -e

function download_and_check () {
  local to=$1
  local url=$2
  local sha256=$3

  curl -fsSL --output "${to}" "${url}"
  echo "${sha256}  ${to}" | sha256sum --check
}

function install_gn(){
  # Install gn tools which will be used for building wee8
  if [[ "$(uname -m)" == "x86_64" ]]; then
    wget -O gntool.zip https://chrome-infra-packages.appspot.com/dl/gn/gn/linux-amd64/+/latest
    unzip gntool.zip -d gntool
    cp gntool/gn /usr/local/bin/gn
    chmod +x /usr/local/bin/gn
    rm -rf gntool*
  elif [[ "$(uname -m)" == "aarch64" ]]; then
    # install gn tools
    download_and_check /usr/local/bin/gn https://github.com/envoyproxy/envoy-build-tools/releases/download/build-tools/gn-arm64 \
      37f2960d488251760c56683dcf2cc4dfb2c2c13af476f86475eee206fafe21e2
    chmod +x /usr/local/bin/gn
  fi
}

if [[ "$(uname -m)" == "x86_64" ]]; then
  # buildifier
  VERSION=5.0.1
  download_and_check /usr/local/bin/buildifier https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildifier-linux-amd64 \
    3ed7358c7c6a1ca216dc566e9054fd0b97a1482cb0b7e61092be887d42615c5d
  chmod +x /usr/local/bin/buildifier

  # buildozer
  download_and_check /usr/local/bin/buildozer https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildozer-linux-amd64 \
    78204dac0ac6a94db499c57c5334b9c0c409d91de9779032c73ad42f2362e901
  chmod +x /usr/local/bin/buildozer

  # bazelisk
  VERSION=1.10.1
  download_and_check /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v${VERSION}/bazelisk-linux-amd64 \
    4cb534c52cdd47a6223d4596d530e7c9c785438ab3b0a49ff347e991c210b2cd
  chmod +x /usr/local/bin/bazel
fi

if [[ "$(uname -m)" == "aarch64" ]]; then
  # bazelisk
  VERSION=1.10.1
  download_and_check /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v${VERSION}/bazelisk-linux-arm64 \
    c1de6860dd4f8d5e2ec270097bd46d6a211b971a0b8b38559784bd051ea950a1
  chmod +x /usr/local/bin/bazel
fi

LLVM_RELEASE="clang+llvm-${LLVM_VERSION}-${LLVM_DISTRO}"
LLVM_DOWNLOAD_PREFIX=${LLVM_DOWNLOAD_PREFIX:-https://github.com/llvm/llvm-project/releases/download/llvmorg-}
download_and_check "${LLVM_RELEASE}.tar.xz" "${LLVM_DOWNLOAD_PREFIX}${LLVM_VERSION}/${LLVM_RELEASE}.tar.xz" "${LLVM_SHA256SUM}"
mkdir /opt/llvm
tar Jxf "${LLVM_RELEASE}.tar.xz" --strip-components=1 -C /opt/llvm
chown -R root:root /opt/llvm
rm "./${LLVM_RELEASE}.tar.xz"
echo "/opt/llvm/lib" > /etc/ld.so.conf.d/llvm.conf
ldconfig

# Install gn tools.
install_gn

# Install lcov
LCOV_VERSION=1.14
download_and_check lcov-${LCOV_VERSION}.tar.gz https://github.com/linux-test-project/lcov/releases/download/v${LCOV_VERSION}/lcov-${LCOV_VERSION}.tar.gz \
  14995699187440e0ae4da57fe3a64adc0a3c5cf14feab971f8db38fb7d8f071a
tar zxf lcov-${LCOV_VERSION}.tar.gz
make -C lcov-${LCOV_VERSION} install
rm -rf "lcov-${LCOV_VERSION}" "./lcov-${LCOV_VERSION}.tar.gz"


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
