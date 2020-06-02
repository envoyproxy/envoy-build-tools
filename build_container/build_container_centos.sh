#!/bin/bash

set -e
ARCH="$(uname -m)"
# Note: rh-git218 is needed to run `git -C` in docs build process.
if [[ "${ARCH}" == "x86_64" ]]; then
  yum install -y centos-release-scl epel-release
fi
yum update -y
yum install -y devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils java-1.8.0-openjdk-headless rsync \
    rh-git218 wget unzip which make cmake3 patch ninja-build devtoolset-9-libatomic-devel openssl python27 \
    libtool autoconf tcpdump graphviz doxygen sudo

ln -s /usr/bin/cmake3 /usr/bin/cmake

# For LLVM to pick right libstdc++
ln -s /opt/rh/devtoolset-9/root/usr/lib/gcc/x86_64-redhat-linux/9 /usr/lib/gcc/x86_64-redhat-linux

# SLES 11 has older glibc than CentOS 7, so pre-built binary for it works on CentOS 7
LLVM_VERSION=10.0.0

case $ARCH in
    'x86_64' )
        LLVM_DISTRO="x86_64-linux-sles11.3"
        LLVM_SHA256SUM="a7a3c2a7aff813bb10932636a6f1612e308256a5e6b5a5655068d5c5b7f80e86"
        ;;
    'aarch64' )
        LLVM_DISTRO="aarch64-linux-gnu"
        LLVM_SHA256SUM="c2072390dc6c8b4cc67737f487ef384148253a6a97b38030e012c4d7214b7295"
        ;;
esac

# httpd24 is equired by rh-git218
echo "/opt/rh/httpd24/root/usr/lib64" > /etc/ld.so.conf.d/httpd24.conf
ldconfig

# Setup tcpdump for non-root.
groupadd pcap
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

# The build_container_common.sh will be skipped when building centOS
# image on Arm64 platform since some building issues are still unsolved. 
# It will be fixed until those issues solved on Arm64 platform.
if [[ $(uname -m) == "aarch64" ]] && grep -q -e rhel /etc/*-release ; then
  echo "Now, the CentOS image can not be built on arm64 platform!"
  exit 0
fi

source ./build_container_common.sh

yum clean all
