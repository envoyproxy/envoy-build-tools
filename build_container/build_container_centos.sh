#!/bin/bash

set -e
ARCH="$(uname -m)"

YUM_PKGS=(
    autoconf
    devtoolset-9-binutils
    devtoolset-9-gcc
    devtoolset-9-gcc-c++
    devtoolset-9-libatomic-devel
    doxygen
    glibc-static
    graphviz
    java-1.8.0-openjdk-headless
    jq
    libstdc++-static
    libtool
    make
    openssl
    patch
    python27
    rsync
    sudo
    tcpdump
    unzip
    wget
    which)

yum update -y -q
yum install -y -q "${YUM_PKGS[@]}"

# For LLVM to pick right libstdc++
ln -s /opt/rh/devtoolset-9/root/usr/lib/gcc/x86_64-redhat-linux/9 /usr/lib/gcc/x86_64-redhat-linux

# The build_container_common.sh will be skipped when building centOS
# image on Arm64 platform since some building issues are still unsolved.
# It will be fixed until those issues solved on Arm64 platform.
if [[ $(uname -m) == "aarch64" ]] && grep -q -e rhel /etc/*-release ; then
  echo "Now, the CentOS image can not be built on arm64 platform!"
  exit 0
fi

source ./build_container_common.sh
install_build
yum clean all
