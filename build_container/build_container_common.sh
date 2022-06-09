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
  case "$(uname -m)" in
  "x86_64")
    GN_ARCH=amd64
    ;;

  "aarch64")
    GN_ARCH=arm64
    ;;
  esac

  wget -O gntool.zip "https://chrome-infra-packages.appspot.com/dl/gn/gn/linux-${GN_ARCH}/+/latest"
  unzip gntool.zip -d gntool
  cp gntool/gn /usr/local/bin/gn
  chmod +x /usr/local/bin/gn
  rm -rf gntool*
}

if [[ "$(uname -m)" == "x86_64" ]]; then
  # buildifier
  VERSION=5.1.0
  download_and_check /usr/local/bin/buildifier https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildifier-linux-amd64 \
    52bf6b102cb4f88464e197caac06d69793fa2b05f5ad50a7e7bf6fbd656648a3
  chmod +x /usr/local/bin/buildifier

  # buildozer
  download_and_check /usr/local/bin/buildozer https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildozer-linux-amd64 \
    7346ce1396dfa9344a5183c8e3e6329f067699d71c4391bd28317391228666bf
  chmod +x /usr/local/bin/buildozer

  # bazelisk
  VERSION=1.11.0
  download_and_check /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v${VERSION}/bazelisk-linux-amd64 \
    231ec5ca8115e94c75a1f4fbada1a062b48822ca04f21f26e4cb1cd8973cd458
  chmod +x /usr/local/bin/bazel
fi

if [[ "$(uname -m)" == "aarch64" ]]; then
  # buildifier
  VERSION=5.1.0
  download_and_check /usr/local/bin/buildifier https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildifier-linux-arm64 \
    917d599dbb040e63ae7a7e1adb710d2057811902fdc9e35cce925ebfd966eeb8
  chmod +x /usr/local/bin/buildifier

  # buildozer
  download_and_check /usr/local/bin/buildozer https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildozer-linux-arm64 \
    0b08e384709ec4d4f5320bf31510d2cefe8f9e425a6565b31db06b2398ff9dc4
  chmod +x /usr/local/bin/buildozer

  # bazelisk
  VERSION=1.11.0
  download_and_check /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v${VERSION}/bazelisk-linux-arm64 \
    f9119deb1eeb6d730ee8b2e1a14d09cb45638f0447df23144229c5b3b3bc2408
  chmod +x /usr/local/bin/bazel
fi

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
