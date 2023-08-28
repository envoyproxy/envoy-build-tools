#!/bin/bash

set -e

# NB: The apt repository keys that are setup here can expire
#   For this reason it is generally good to ensure that the image is
#   updated every few months, to ensure ~fresh keys.

ARCH="$(uname -m)"

# Setup basic requirements and install them.
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends locales software-properties-common apt-transport-https curl gpg-agent g++

LSB_RELEASE="$(lsb_release -cs)"

# set locale
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# gdb
add-apt-repository -y ppa:ubuntu-toolchain-r/test

# docker-ce-cli
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
case $ARCH in
    'ppc64le' )
        DEB_ARCH=ppc64le
        ;;
    'x86_64' )
        DEB_ARCH=amd64
        ;;
    'aarch64' )
        DEB_ARCH=arm64
        ;;
esac

add-apt-repository "deb [arch=${DEB_ARCH}] https://download.docker.com/linux/ubuntu ${LSB_RELEASE} stable"

# Python
add-apt-repository ppa:deadsnakes/ppa

apt-get update -y

PACKAGES=(
    automake
    bc
    bzip2
    cmake
    cmake-data
    devscripts
    docker-ce-cli
    doxygen
    gdb
    git
    gnupg2
    graphviz
    jq
    libffi-dev
    libncurses-dev
    libtool
    make
    ninja-build
    patch
    python3.10
    python3.10-dev
    python3.10-distutils
    rpm
    rsync
    ssh-client
    strace
    sudo
    tcpdump
    time
    tshark
    unzip
    wget
    xz-utils
    zip)

apt-get install -y --no-install-recommends "${PACKAGES[@]}"

case $ARCH in
    'ppc64le' )
        LLVM_DISTRO="$LLVM_DISTRO_PPC64LE"
        LLVM_SHA256SUM="$LLVM_SHA256SUM_PPC64LE"
        BAZEL_LATEST="$(curl https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/latest/ 2>&1 \
          | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep '^bazel' | head -n 1)"
        curl -fSL "https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/latest/${BAZEL_LATEST}" \
          -o /usr/local/bin/bazel
        chmod +x /usr/local/bin/bazel
        ;;
    'aarch64' )
        LLVM_DISTRO="$LLVM_DISTRO_ARM64"
        LLVM_SHA256SUM="$LLVM_SHA256SUM_ARM64"
        apt-get install -y --no-install-recommends libtinfo5 # LLVM dependencies on Ubuntu 20.04
        ;;
esac

# additional apt installs
apt-get install -y aspell expect
rm -rf /var/lib/apt/lists/*

# Setup tcpdump for non-root.
groupadd -r pcap
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

# Get pip for python3.10
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# make python3.10 the default python3 interpreter
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

source ./build_container_common.sh

# pip installs
# TODO(phlax): use hashed requirements
pip3 install --no-cache-dir -U pyyaml virtualenv

apt-get -qq remove --purge -y cmake* ninja-build
apt-get clean
