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

# Use prebuilt Clang+LLVM from GetEnvoy, build logs:
# http://storage.googleapis.com/getenvoy-package/clang-toolchain/0e9d364b7199f3aaecbaf914cea3d9df4e97b850/artifacts-6cecd977-3051-4713-aba3-0d503691befc.json
LLVM_PREBUILT=https://storage.googleapis.com/getenvoy-package/clang-toolchain/0e9d364b7199f3aaecbaf914cea3d9df4e97b850/clang+llvm-9.0.0-x86_64-linux-centos7.tar.xz
mkdir -p /opt/llvm
curl -sSL "${LLVM_PREBUILT}" | tar Jx --strip-components=1 -C /opt/llvm

# httpd24 is equired by rh-git218
echo "/opt/rh/httpd24/root/usr/lib64" > /etc/ld.so.conf.d/httpd24.conf
echo "/opt/llvm/lib" > /etc/ld.so.conf.d/llvm.conf
ldconfig

# Setup tcpdump for non-root.
groupadd pcap
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

./build_container_common.sh
