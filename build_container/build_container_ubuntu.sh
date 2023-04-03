#!/bin/bash

set -e

ARCH="$(uname -m)"

# Setup basic requirements and install them.
apt-get update -y
apt-get install -y --no-install-recommends locales software-properties-common apt-transport-https curl gpg-agent g++

# set locale
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Python3.10 dev headers only
# TODO(phlax): figure if this is necessary, almost certainly its only needed for arm if at all
add-apt-repository ppa:deadsnakes/ppa

PACKAGES=(
    aspell
    bc
    bzip2
    devscripts
    expect
    git
    gnupg2
    graphviz
    jq
    patch
    python3
    python3-distutils
    python3-pip
    python3.10-dev
    rpm
    rsync
    ssh-client
    strace
    sudo
    time
    unzip
    wget
    xz-utils
    zip)

apt-get install -y --no-install-recommends "${PACKAGES[@]}"

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

source ./build_container_common.sh

# pip installs
# TODO(phlax): use hashed requirements
pip3 install --no-cache-dir -U pyyaml virtualenv

apt-get -qq remove --purge -y cmake* ninja-build
apt-get clean
