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
    libtool autoconf tcpdump graphviz doxygen

ln -s /usr/bin/cmake3 /usr/bin/cmake
ln -s /usr/bin/ninja-build /usr/bin/ninja

# For LLVM to pick right libstdc++
ln -s /opt/rh/devtoolset-9/root/usr/lib/gcc/x86_64-redhat-linux/9 /usr/lib/gcc/x86_64-redhat-linux

# SLES 11 has older glibc than CentOS 7, so pre-built binary for it works on CentOS 7
LLVM_VERSION=9.0.0

case $ARCH in
    'x86_64' )
        LLVM_DISTRO="x86_64-linux-sles11.3"
        LLVM_SHA256SUM="c80b5b10df191465df8cee8c273d9c46715e6f27f80fef118ad4ebb7d9f3a7d3"
        ;;
    'aarch64' )
        LLVM_DISTRO="aarch64-linux-gnu"
        LLVM_SHA256SUM="f8f3e6bdd640079a140a7ada4eb6f5f05aeae125cf54b94d44f733b0e8691dc2"
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
