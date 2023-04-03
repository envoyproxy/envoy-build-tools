#!/bin/bash -e

ARCH="$(uname -m)"

case $ARCH in
    'ppc64le' )
        LLVM_DISTRO=powerpc64le-linux-ubuntu-18.04
        LLVM_SHA256SUM=2d504c4920885c86b306358846178bc2232dfac83b47c3b1d05861a8162980e6
        ;;
    'x86_64' )
        LLVM_DISTRO=x86_64-linux-gnu-ubuntu-18.04
        LLVM_SHA256SUM=61582215dafafb7b576ea30cc136be92c877ba1f1c31ddbbd372d6d65622fef5
        ;;
    'aarch64' )
        LLVM_DISTRO=aarch64-linux-gnu
        LLVM_SHA256SUM=1792badcd44066c79148ffeb1746058422cc9d838462be07e3cb19a4b724a1ee
        ;;
esac

source ./build_container_llvm.sh

# CMake
curl -fsSL https://apt.kitware.com/keys/kitware-archive-latest.asc | apt-key add -
apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"

# gdb
add-apt-repository -y ppa:ubuntu-toolchain-r/test

apt-get -qq update
PACKAGES=(
    automake
    cmake
    cmake-data
    doxygen
    gdb
    libffi-dev
    libncurses-dev
    libtool
    make
    ninja-build
    tcpdump
    tshark)


if [[ "$ARCH" == "aarch64" ]]; then
    # LLVM dependencies on Ubuntu 20.04
    PACKAGES+=(libtinfo5)
fi

apt-get -qq install -y --no-install-recommends "${PACKAGES[@]}"

# Setup tcpdump for non-root.
groupadd -r pcap
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
