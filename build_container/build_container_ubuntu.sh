#!/bin/bash

set -e

ARCH="$(uname -m)"

# Setup basic requirements and install them.
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends locales software-properties-common apt-transport-https curl gpg-agent g++

# set locale
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Google Cloud SDK
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
  | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# docker-ce-cli
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# CMake
curl -fsSL https://apt.kitware.com/keys/kitware-archive-latest.asc | apt-key add -
apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"

# Python
add-apt-repository ppa:deadsnakes/ppa

apt-get update -y

PACKAGES=(
    automake
    bc
    bzip2
    cmake
    cmake-data
    devscripts
    docker-ce-cli
    doxygen
    gdb
    git
    gnupg2
    graphviz
    jq
    libffi-dev
    libncurses-dev
    libtinfo5
    libtool
    make
    ninja-build
    patch
    python3.10
    python3.10-dev
    python3.10-distutils
    rpm
    rsync
    ssh-client
    strace
    sudo
    tcpdump
    time
    tshark
    unzip
    wget
    xz-utils
    zip)

if [[ "${ARCH}" == "x86_64" || "${ARCH}" == "aarch64" ]]; then
  PACKAGES+=("google-cloud-sdk")
fi

apt-get install -y --no-install-recommends "${PACKAGES[@]}"

# Set LLVM version for each cpu architecture.
LLVM_VERSION=14.0.0
case $ARCH in
    'ppc64le' )
        LLVM_DISTRO=powerpc64le-linux-ubuntu-18.04
        LLVM_SHA256SUM=2d504c4920885c86b306358846178bc2232dfac83b47c3b1d05861a8162980e6
        ;;
    'x86_64' )
        LLVM_DISTRO=x86_64-linux-gnu-ubuntu-18.04
        LLVM_SHA256SUM=61582215dafafb7b576ea30cc136be92c877ba1f1c31ddbbd372d6d65622fef5
        ;;
    'aarch64' )
        LLVM_DISTRO=aarch64-linux-gnu
        LLVM_SHA256SUM=1792badcd44066c79148ffeb1746058422cc9d838462be07e3cb19a4b724a1ee
        ;;
esac

# Bazel and related dependencies.
case $ARCH in
    'ppc64le' )
        BAZEL_LATEST="$(curl https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_$(lsb_release -r | awk '{print $2}')/latest/ 2>&1 \
          | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep '^bazel' | head -n 1)"
        curl -fSL https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_$(lsb_release -r | awk '{print $2}')/latest/${BAZEL_LATEST} \
          -o /usr/local/bin/bazel
        chmod +x /usr/local/bin/bazel
        ;;
esac

# additional apt installs
apt-get install -y aspell expect
rm -rf /var/lib/apt/lists/*

# Setup tcpdump for non-root.
groupadd -r pcap
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

# Get pip for python3.10
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# make python3.10 the default python3 interpreter
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

# pip installs
# TODO(phlax): use hashed requirements
pip3 install -U pyyaml virtualenv

source ./build_container_common.sh

# Soft link the gcc compiler (required by python env)
ARCH=${ARCH/ppc64le/powerpc64le} # For ppc64le the ARCH variable must be renamed accordingly
update-alternatives --install "/usr/bin/${ARCH}-linux-gnu-gcc" "${ARCH}-linux-gnu-gcc" "/usr/bin/${ARCH}-linux-gnu-gcc-9" 1

apt-get clean
