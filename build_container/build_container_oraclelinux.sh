#!/bin/bash

set -e
ARCH="$(uname -m)"

yum-config-manager --enable ol8_codeready_builder
yum update -y

yum install -y \
  binutils \
  cmake \
  gcc \
  git \
  glibc-langpack-en \
  glibc-locale-source \
  glibc-static \
  libstdc++-static \
  ncurses-compat-libs \
  ninja-build \
  perl \
  python3 \
  tcpdump \
  unzip \
  wget \
  xz \
  sudo

# set locale
localedef -c -f UTF-8 -i en_US en_US.UTF-8
export LC_ALL=en_US.UTF-8

# For LLVM to pick right libstdc++
ln -s /opt/rh/devtoolset-9/root/usr/lib/gcc/x86_64-redhat-linux/9 /usr/lib/gcc/x86_64-redhat-linux

LLVM_VERSION=15.0.0

case $ARCH in
    'x86_64' )
        LLVM_DISTRO="x86_64-linux-gnu-rhel-8.4"
        LLVM_SHA256SUM="20b17fabc97b93791098e771adf18013c50eae2e45407f8bfa772883b6027d30"
        ;;
    'aarch64' )
        LLVM_DISTRO="aarch64-linux-gnu"
        LLVM_SHA256SUM="527ed550784681f95ec7a1be8fbf5a24bd03d7da9bf31afb6523996f45670be3"
        ;;
esac

# httpd24 is equired by rh-git218
echo "/opt/rh/httpd24/root/usr/lib64" > /etc/ld.so.conf.d/httpd24.conf
ldconfig

# Setup tcpdump for non-root.
groupadd -r pcap
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

source ./build_container_common.sh

# compile proper version of gn, compatible with Oracle Linux's GLIBC version and
# envoy wasm/v8 dependency
# can be removed when the dependency will be updated
git clone https://gn.googlesource.com/gn
pushd gn
# 45aa842fb41d79e149b46fac8ad71728856e15b9 is a hash of the version
# before https://gn.googlesource.com/gn/+/46b572ce4ceedfe57f4f84051bd7da624c98bf01
# as this commit expects envoy to rely on newer version of wasm/v8 with the fix
# from https://github.com/v8/v8/commit/eac21d572e92a82f5656379bc90f8ecf1ff884fc
# (versions 9.5.164 - 9.6.152)
git checkout 45aa842fb41d79e149b46fac8ad71728856e15b9
python3 build/gen.py
ninja -C out
mv -f out/gn /usr/local/bin/gn
chmod +x /usr/local/bin/gn
popd

yum clean all
