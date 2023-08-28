#!/bin/bash -e

set -o pipefail

ARCH="$(uname -m)"
YUM_PKGS=(
    autoconf
    cmake3
    devtoolset-9-binutils
    devtoolset-9-gcc
    devtoolset-9-gcc-c++
    devtoolset-9-libatomic-devel
    glibc-static
    java-1.8.0-openjdk-headless
    libstdc++-static
    libtool
    make
    ninja-build
    patch
    openssl
    python27
    sudo)

install_gn () {
    # compile proper version of gn, compatible with CentOS's GLIBC version and
    # envoy wasm/v8 dependency
    # can be removed when the dependency will be updated
    git clone https://gn.googlesource.com/gn
    pushd gn
    # 45aa842fb41d79e149b46fac8ad71728856e15b9 is a hash of the version
    # before https://gn.googlesource.com/gn/+/46b572ce4ceedfe57f4f84051bd7da624c98bf01
    # as this commit expects envoy to rely on newer version of wasm/v8 with the fix
    # from https://github.com/v8/v8/commit/eac21d572e92a82f5656379bc90f8ecf1ff884fc
    # (versions 9.5.164 - 9.6.152)
    git checkout 45aa842fb41d79e149b46fac8ad71728856e15b9
    python build/gen.py
    ninja -C out
    mv -f out/gn /usr/local/bin/gn
    chmod +x /usr/local/bin/gn
    popd
}

yum update -y -q
yum install -y -q "${YUM_PKGS[@]}"

ln -s /usr/bin/cmake3 /usr/bin/cmake

# For LLVM to pick right libstdc++
ln -s /opt/rh/devtoolset-9/root/usr/lib/gcc/x86_64-redhat-linux/9 /usr/lib/gcc/x86_64-redhat-linux

if [[ "$ARCH" == "aarch64" ]]; then
    LLVM_DISTRO="$LLVM_DISTRO_ARM64"
    LLVM_SHA256SUM="$LLVM_SHA256SUM_ARM64"
fi

# The build_container_common.sh will be skipped when building centOS
# image on Arm64 platform since some building issues are still unsolved.
# It will be fixed until those issues solved on Arm64 platform.
if [[ $(uname -m) == "aarch64" ]] && grep -q -e rhel /etc/*-release ; then
  echo "Now, the CentOS image can not be built on arm64 platform!"
  mkdir /opt/libcxx_msan
  mkdir /opt/libcxx_tsan
  exit 0
fi

source ./build_container_llvm.sh
install_gn
