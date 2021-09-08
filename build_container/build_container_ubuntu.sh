#!/bin/bash

set -e

ARCH="$(uname -m)"

# Setup basic requirements and install them.
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends locales software-properties-common apt-transport-https curl gpg-agent

# set locale
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# gcc-9
add-apt-repository -y ppa:ubuntu-toolchain-r/test
apt-get update
apt-get install -y --no-install-recommends g++-9
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 1000
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 1000
update-alternatives --config gcc
update-alternatives --config g++

# Google Cloud SDK
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
  | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# docker-ce-cli
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
case $ARCH in
    'ppc64le' )
        add-apt-repository "deb [arch=ppc64le] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        ;;
    'x86_64' )
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        ;;
    'aarch64' )
        add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        ;;
esac

# CMake
curl -fsSL https://apt.kitware.com/keys/kitware-archive-latest.asc | apt-key add -
apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"

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
    google-cloud-sdk
    graphviz
    jq
    libncurses-dev
    libtool
    make
    ninja-build
    patch
    python
    python-pip
    python-setuptools
    python3
    python3-pip
    python3-setuptools
    python3.8
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

# Set LLVM version for each cpu architecture.
LLVM_VERSION=11.0.1
case $ARCH in
    'ppc64le' )
        LLVM_DISTRO=powerpc64le-linux-ubuntu-18.04
        LLVM_SHA256SUM=a60a35f6c9f280268df8afe76f4a5349426f8b8eefd40eb885eae80b6e3647d0
        ;;
    'x86_64' )
        LLVM_DISTRO=x86_64-linux-gnu-ubuntu-16.04
        LLVM_SHA256SUM=67f18660231d7dd09dc93502f712613247b7b4395e6f48c11226629b250b53c5
        ;;
    'aarch64' )
        LLVM_DISTRO=aarch64-linux-gnu
        LLVM_SHA256SUM=39b3d3e3b534e327d90c77045058e5fc924b1a81d349eac2be6fb80f4a0e40d4
        ;;
esac

# Bazel and related dependencies.
case $ARCH in
    'ppc64le' )
        BAZEL_LATEST="$(curl https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/latest/ 2>&1 \
          | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep '^bazel' | head -n 1)"
        curl -fSL https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/latest/${BAZEL_LATEST} \
          -o /usr/local/bin/bazel
        chmod +x /usr/local/bin/bazel
        ;;
    'aarch64' )
        if [ "$(lsb_release -cs)" == 'xenial' ]; then
          apt install -y openjdk-8-jdk
          apt install -y ca-certificates-java
          update-ca-certificates -f
        else
          apt install -y openjdk-11-jdk
        fi
        ;;
esac

# additional apt installs
apt-get install -y aspell expect
rm -rf /var/lib/apt/lists/*

# upstream install of shellcheck (taken from https://askubuntu.com/a/1228181)
pushd /tmp || exit 1
echo "c37d4f51e26ec8ab96b03d84af8c050548d7288a47f755ffb57706c6c458e027  /tmp/shellcheck-v0.7.0/shellcheck" > sc.checksum
wget -qO- https://github.com/koalaman/shellcheck/releases/download/v0.7.0/shellcheck-v0.7.0.linux.x86_64.tar.xz | tar -xJf -
sha256sum -c sc.checksum
sudo cp shellcheck-v0.7.0/shellcheck /usr/local/bin
rm -rf shellcheck-v0.7.0/ sc.checksum
popd || exit 1

# Setup tcpdump for non-root.
groupadd -r pcap
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

# make python3.8 the default python3 interpreter
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1

# virtualenv
pip3 install -U virtualenv

source ./build_container_common.sh

apt-get clean
