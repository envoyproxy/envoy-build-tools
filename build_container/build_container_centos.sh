#!/bin/bash

set -e

# Note: rh-git218 is needed to run `git -C` in docs build process.
yum install -y centos-release-scl epel-release
yum update -y
yum install -y devtoolset-7-gcc devtoolset-7-gcc-c++ devtoolset-7-binutils java-1.8.0-openjdk-headless rsync \
    rh-git218 wget unzip which make cmake3 patch ninja-build devtoolset-7-libatomic-devel openssl python27 \
    libtool autoconf tcpdump

ln -s /usr/bin/cmake3 /usr/bin/cmake
ln -s /usr/bin/ninja-build /usr/bin/ninja

# SLES 11 has older glibc than CentOS 7, so pre-built binary for it works on CentOS 7
LLVM_VERSION=9.0.0
LLVM_DISTRO="x86_64-linux-sles11.3"
LLVM_SHA256SUM="c80b5b10df191465df8cee8c273d9c46715e6f27f80fef118ad4ebb7d9f3a7d3"

# httpd24 is equired by rh-git218
echo "/opt/rh/httpd24/root/usr/lib64" > /etc/ld.so.conf.d/httpd24.conf
ldconfig

# Setup tcpdump for non-root.
groupadd pcap
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

source ./build_container_common.sh
