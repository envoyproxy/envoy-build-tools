#!/bin/bash

set -e

ARCH="$(uname -m)"

# Setup basic requirements and install them.
apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends software-properties-common apt-transport-https curl

# gcc-7
add-apt-repository -y ppa:ubuntu-toolchain-r/test
apt-get update
apt-get install -y --no-install-recommends g++-7
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 1000
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 1000
update-alternatives --config gcc
update-alternatives --config g++

# docker-ce-cli
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
case $ARCH in
    'ppc64le' )
        add-apt-repository "deb [arch=ppc64le] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        ;;
    'x86_64' )
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        ;;
esac
apt-get update

apt-get install -y --no-install-recommends docker-ce-cli wget make cmake git python python-pip python-setuptools python3 python3-pip \
  unzip bc libtool ninja-build automake zip time gdb strace tshark tcpdump patch xz-utils rsync ssh-client

LLVM_VERSION=9.0.0
case $ARCH in
    'ppc64le' )
        LLVM_DISTRO=powerpc64le-linux-ubuntu-16.04
        LLVM_SHA256SUM=a8e7dc00e9eac47ea769eb1f5145e1e28f0610289f07f3275021f0556c169ddf
        ;;
    'x86_64' )
        LLVM_DISTRO=x86_64-linux-gnu-ubuntu-16.04
        LLVM_SHA256SUM=5c1473c2611e1eac4ed1aeea5544eac5e9d266f40c5623bbaeb1c6555815a27d
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
esac

apt-get install -y aspell
rm -rf /var/lib/apt/lists/*

# Setup tcpdump for non-root.
groupadd pcap
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

# virtualenv
pip3 install virtualenv

source ./build_container_common.sh

apt-get clean
