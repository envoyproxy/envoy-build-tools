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
  VERSION=1.6.0
  download_and_check /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v${VERSION}/bazelisk-linux-amd64 \
    616f65bcdcfd134a19d5d86c591c35098d7732be26145bf06f02ec9e3e52700c
  chmod +x /usr/local/bin/bazel
fi

if [[ "$(uname -m)" == "aarch64" ]]; then
  # bazelisk
  VERSION=1.6.0
  download_and_check /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v${VERSION}/bazelisk-linux-arm64 \
    4a74d233008ec4a59d07fd8ba67cb4acbf7331acb0458aead16f8a4eb1995f9e
  chmod +x /usr/local/bin/bazel
fi

LLVM_RELEASE="clang+llvm-${LLVM_VERSION}-${LLVM_DISTRO}"
LLVM_DOWNLOAD_PREFIX=${LLVM_DOWNLOAD_PREFIX:-https://github.com/llvm/llvm-project/releases/download/llvmorg-}
download_and_check "${LLVM_RELEASE}.tar.xz" "${LLVM_DOWNLOAD_PREFIX}${LLVM_VERSION}/${LLVM_RELEASE}.tar.xz" "${LLVM_SHA256SUM}"
tar Jxf "${LLVM_RELEASE}.tar.xz"
mv "./${LLVM_RELEASE}" /opt/llvm
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
  exit 0
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

  if [[ ! -z "$(diff -r /opt/libcxx_${LIBCXX_PATH}/include/c++ /opt/llvm/include/c++)" ]]; then
    echo "Different libc++ is installed";
    exit 1
  fi

  rm -rf "/opt/libcxx_${LIBCXX_PATH}/include"

  popd
}

install_libcxx MemoryWithOrigins msan
install_libcxx Thread tsan

popd
