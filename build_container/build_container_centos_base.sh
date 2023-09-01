#!/bin/bash -e

set -o pipefail

ARCH="$(uname -m)"

# Note: rh-git218 is needed to run `git -C` in docs build process.
# httpd24 is equired by rh-git218
YUM_PACKAGES=(
    devtoolset-9-binutils
    devtoolset-9-gcc
    devtoolset-9-gcc-c++
    devtoolset-9-libatomic-devel
    glibc-static
    libstdc++-static
    rh-git218
    wget)

localedef -c -f UTF-8 -i en_US en_US.UTF-8

if [[ "${ARCH}" == "x86_64" ]]; then
    yum install -y centos-release-scl epel-release
fi

yum update -y -q
yum install -y -q "${YUM_PACKAGES[@]}"
echo "/opt/rh/httpd24/root/usr/lib64" > /etc/ld.so.conf.d/httpd24.conf
ldconfig
