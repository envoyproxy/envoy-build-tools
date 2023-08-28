#!/bin/bash

set -e

# NB: The apt repository keys that are setup here can expire
#   For this reason it is generally good to ensure that the image is
#   updated every few months, to ensure ~fresh keys.

ARCH="$(uname -m)"

PACKAGES=(
    automake
    bzip2
    cmake
    cmake-data
    git
    libffi-dev
    libtool
    make
    ninja-build
    patch
    unzip
    wget
    xz-utils)

install_gn(){
    # Install gn tools which will be used for building wee8
    wget -O gntool.zip "https://chrome-infra-packages.appspot.com/dl/gn/gn/linux-${DEB_ARCH}/+/latest"
    unzip -q gntool.zip -d gntool
    cp gntool/gn /usr/local/bin/gn
    chmod +x /usr/local/bin/gn
    rm -rf gntool*
}

apt-get -qq update -y
apt-get -qq install -y --no-install-recommends "${PACKAGES[@]}"

case $ARCH in
    'ppc64le' )
        LLVM_DISTRO="$LLVM_DISTRO_PPC64LE"
        LLVM_SHA256SUM="$LLVM_SHA256SUM_PPC64LE"
        ;;
    'aarch64' )
        LLVM_DISTRO="$LLVM_DISTRO_ARM64"
        LLVM_SHA256SUM="$LLVM_SHA256SUM_ARM64"
        ;;
esac

source ./build_container_llvm.sh
install_gn
