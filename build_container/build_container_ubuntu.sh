#!/bin/bash

set -e

ARCH="$(uname -m)"

# Setup basic requirements and install them.
apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends software-properties-common apt-transport-https curl

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
apt-get update -y

apt-get install -y --no-install-recommends docker-ce-cli wget make cmake git python python-pip python-setuptools python3 python3-pip \
  python3-setuptools python3-yaml unzip bc libtool automake zip time gdb strace tshark tcpdump patch xz-utils rsync ssh-client \
  google-cloud-sdk libncurses-dev doxygen graphviz

# Python 3.8
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt install -y python3.8

# Install ninja-build 1.8.2 from binary
case $ARCH in
    'ppc64le' )
        ninja_deb="ninja-build_1.8.2-1_ppc64el.deb"
        ;;
    'x86_64' )
        ninja_deb="ninja-build_1.8.2-1_amd64.deb"
        ;;
    'aarch64' )
        ninja_deb="ninja-build_1.8.2-1_arm64.deb"
        ;;
esac
wget https://launchpad.net/ubuntu/+archive/primary/+files/${ninja_deb}
dpkg -i ${ninja_deb}
rm ${ninja_deb}

# Set LLVM version for each cpu architecture.
case $ARCH in
    'ppc64le' )
        LLVM_VERSION=9.0.0
        LLVM_DISTRO=powerpc64le-linux-ubuntu-16.04
        LLVM_SHA256SUM=a8e7dc00e9eac47ea769eb1f5145e1e28f0610289f07f3275021f0556c169ddf
        ;;
    'x86_64' )
        LLVM_VERSION=9.0.0
        LLVM_DISTRO=x86_64-linux-gnu-ubuntu-16.04
        LLVM_SHA256SUM=5c1473c2611e1eac4ed1aeea5544eac5e9d266f40c5623bbaeb1c6555815a27d
        ;;
    'aarch64' )
        # When using clang 9.0.0 to build envoy test, there are some errors about toolchain.
        # So we just use an older version to walk-around until clang 10.0.0 pubished.
        LLVM_VERSION=8.0.0
        LLVM_DISTRO=aarch64-linux-gnu
        LLVM_SHA256SUM=998e9ae6e89bd3f029ed031ad9355c8b43441302c0e17603cf1de8ee9939e5c9
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
