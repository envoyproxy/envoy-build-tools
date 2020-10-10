#!/bin/bash

set -e

ARCH="$(uname -m)"

# Setup basic requirements and install them.
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends software-properties-common apt-transport-https curl gpg-agent

# gcc-7
apt-get update
apt-get install -y --no-install-recommends g++-7
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 1000
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 1000
update-alternatives --config gcc
update-alternatives --config g++


apt-get update -y

apt-get install -y --no-install-recommends wget make cmake git python python-pip python-setuptools python3 python3-pip \
  python3-setuptools python3-yaml unzip bc libtool automake zip time gdb strace tshark tcpdump patch xz-utils rsync openssh-client \
  libncurses-dev doxygen graphviz ninja-build bzip2 sudo  libc++-dev libc++abi-dev clang gcc-7 g++-7 lld clang-format-7  libgtk2.0-0  \
  build-essential zlib1g-dev pkg-config

# Set LLVM version for each cpu architecture.
LLVM_VERSION=7.0.1
case $ARCH in
    'mips64el')
     apt-get install -y  llvm-7
     mv /usr/lib/llvm-7 /opt/llvm
        ;;
esac

# Bazel and related dependencies.
case $ARCH in
    'mips64el' )
        apt install -y openjdk-11-jdk
        ;;
esac

# additional apt installs
apt-get install -y aspell shellcheck
rm -rf /var/lib/apt/lists/*

# Setup tcpdump for non-root.
groupadd -r pcap
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

## virtualenv
#pip3 install -U virtualenv
pip3 install -U virtualenv -i http://pypi.douban.com/simple --trusted-host pypi.douban.com

source ./build_container_common.sh

apt-get clean
