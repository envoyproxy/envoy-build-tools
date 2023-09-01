#!/bin/bash -e

set -o pipefail

. ./common_fun.sh


YUM_LLVM_PKGS=(
    cmake3
    ninja-build)
# Note: rh-git218 is needed to run `git -C` in docs build process.
# httpd24 is equired by rh-git218
COMMON_PACKAGES=(
    devtoolset-9-binutils
    devtoolset-9-gcc
    devtoolset-9-gcc-c++
    devtoolset-9-libatomic-devel
    glibc-static
    libstdc++-static
    rh-git218
    wget)
YUM_PKGS=(
    autoconf
    doxygen
    graphviz
    java-1.8.0-openjdk-headless
    jq
    libtool
    make
    openssl
    patch
    python27
    rsync
    sudo
    tcpdump
    unzip
    which)


install_base () {
    localedef -c -f UTF-8 -i en_US en_US.UTF-8
    if [[ "${ARCH}" == "x86_64" ]]; then
        yum install -y centos-release-scl epel-release
    fi
    yum update -y -q
    yum install -y -q "${COMMON_PACKAGES[@]}"
    echo "/opt/rh/httpd24/root/usr/lib64" > /etc/ld.so.conf.d/httpd24.conf
    ldconfig
}

install_gn () {
    # compile proper version of gn, compatible with CentOS's GLIBC version and
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
    python build/gen.py
    ninja -C out
    mv -f out/gn /usr/local/bin/gn
    chmod +x /usr/local/bin/gn
    popd
}

install_llvm () {
    yum update -y -q
    yum install -y -q "${YUM_LLVM_PKGS[@]}"
    ln -s /usr/bin/cmake3 /usr/bin/cmake
    # For LLVM to pick right libstdc++
    ln -s /opt/rh/devtoolset-9/root/usr/lib/gcc/x86_64-redhat-linux/9 /usr/lib/gcc/x86_64-redhat-linux
    # The build_container_common.sh will be skipped when building centOS
    # image on Arm64 platform since some building issues are still unsolved.
    # It will be fixed until those issues solved on Arm64 platform.
    if [[ "$ARCH" == "aarch64" ]] && grep -q -e rhel /etc/*-release ; then
        echo "Now, the CentOS image can not be built on arm64 platform!"
        mkdir /opt/libcxx_msan
        mkdir /opt/libcxx_tsan
        exit 0
    fi
    install_llvm_bins
    install_san
    install_gn
}

install () {
    yum update -y -q
    yum install -y -q "${YUM_PKGS[@]}"
    # For LLVM to pick right libstdc++
    ln -s /opt/rh/devtoolset-9/root/usr/lib/gcc/x86_64-redhat-linux/9 /usr/lib/gcc/x86_64-redhat-linux
    # The build_container_common.sh will be skipped when building centOS
    # image on Arm64 platform since some building issues are still unsolved.
    # It will be fixed until those issues solved on Arm64 platform.
    if [[ $(uname -m) == "aarch64" ]] && grep -q -e rhel /etc/*-release ; then
        echo "Now, the CentOS image can not be built on arm64 platform!"
        exit 0
    fi
}
