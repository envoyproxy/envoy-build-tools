#!/bin/bash -e

function download_and_check () {
  local to=$1
  local url=$2
  local sha256=$3

  curl -fsSL --output "${to}" "${url}"
  echo "${sha256}  ${to}" | sha256sum --check
}

if [[ "$(uname -m)" == "x86_64" ]]; then
  # buildifier
  VERSION=0.29.0
  download_and_check /usr/local/bin/buildifier https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildifier \
    4c985c883eafdde9c0e8cf3c8595b8bfdf32e77571c369bf8ddae83b042028d6
  chmod +x /usr/local/bin/buildifier

  # buildozer
  VERSION=0.29.0
  download_and_check /usr/local/bin/buildozer https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildozer \
    2a5c3e3390de07248704f21ed38495062fb623c9b0aef37deda257a917891ea6
  chmod +x /usr/local/bin/buildozer

  # bazelisk
  VERSION=1.0
  download_and_check /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v${VERSION}/bazelisk-linux-amd64 \
    820f1432bb729cf1d51697a64ce57c0cff7ea4013acaf871b8c24b6388174d0d
  chmod +x /usr/local/bin/bazel
fi

LLVM_RELEASE="clang+llvm-${LLVM_VERSION}-${LLVM_DISTRO}"
download_and_check "${LLVM_RELEASE}.tar.xz" "https://releases.llvm.org/${LLVM_VERSION}/${LLVM_RELEASE}.tar.xz" "${LLVM_SHA256SUM}"
tar Jxf "${LLVM_RELEASE}.tar.xz"
mv "./${LLVM_RELEASE}" /opt/llvm
chown -R root:root /opt/llvm
rm "./${LLVM_RELEASE}.tar.xz"
echo "/opt/llvm/lib" > /etc/ld.so.conf.d/llvm.conf
ldconfig

# MSAN
export PATH="/opt/llvm/bin:${PATH}"

WORKDIR=$(mktemp -d)
function cleanup {
  rm -rf "${WORKDIR}"
}

trap cleanup EXIT

cd "${WORKDIR}"

curl -sSfL "https://github.com/llvm/llvm-project/archive/llvmorg-${LLVM_VERSION}.tar.gz" | tar zx

mkdir msan
pushd msan

cmake -GNinja -DLLVM_ENABLE_PROJECTS="libcxxabi;libcxx" -DLLVM_USE_LINKER=lld -DLLVM_USE_SANITIZER=Memory -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_INSTALL_PREFIX="/opt/libcxx_msan" "../llvm-project-llvmorg-${LLVM_VERSION}/llvm"
ninja install-cxx install-cxxabi

if [[ ! -z "$(diff -r /opt/libcxx_msan/include/c++ /opt/llvm/include/c++)" ]]; then
  echo "Different libc++ is installed";
  exit 1
fi

rm -rf /opt/libcxx_msan/include

popd
