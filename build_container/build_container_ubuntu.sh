#!/bin/bash

set -e

ARCH="$(uname -m)"

# Setup basic requirements and install them.
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends software-properties-common apt-transport-https curl gpg-agent

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

apt-get install -y --no-install-recommends docker-ce-cli wget make cmake git python python-pip python-setuptools python3 python3-pip \
  python3-setuptools python3-yaml unzip bc libtool automake zip time gdb strace tshark tcpdump patch xz-utils rsync ssh-client \
  google-cloud-sdk libncurses-dev doxygen graphviz python3.8 ninja-build bzip2 sudo

# Set LLVM version for each cpu architecture.
LLVM_VERSION=10.0.0
case $ARCH in
    'ppc64le' )
        LLVM_DISTRO=powerpc64le-linux-ubuntu-16.04
        LLVM_SHA256SUM=2d6298720d6aae7fcada4e909f0949d63e94fd0370d20b8882cdd91ceae7511c
        ;;
    'x86_64' )
        LLVM_DISTRO=x86_64-linux-gnu-ubuntu-18.04
        LLVM_SHA256SUM=b25f592a0c00686f03e3b7db68ca6dc87418f681f4ead4df4745a01d9be63843
        ;;
    'aarch64' )
        LLVM_DISTRO=aarch64-linux-gnu
        LLVM_SHA256SUM=c2072390dc6c8b4cc67737f487ef384148253a6a97b38030e012c4d7214b7295
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

apt-get install -y aspell
rm -rf /var/lib/apt/lists/*

# Setup tcpdump for non-root.
groupadd pcap
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

# virtualenv
pip3 install -U virtualenv

source ./build_container_common.sh

apt-get clean
