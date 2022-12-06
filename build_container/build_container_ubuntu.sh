#!/bin/bash

set -e

ARCH="$(uname -m)"

# Setup basic requirements and install them.
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends locales software-properties-common apt-transport-https curl gpg-agent g++

# set locale
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# gdb
add-apt-repository -y ppa:ubuntu-toolchain-r/test

# Google Cloud SDK
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
  | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# docker-ce-cli
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
case $ARCH in
    'ppc64le' )
        add-apt-repository "deb [arch=ppc64le] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        ;;
    'x86_64' )
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        ;;
    'aarch64' )
        add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        ;;
esac

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
    google-cloud-sdk
    graphviz
    jq
    libffi-dev
    libncurses-dev
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
        apt-get install -y --no-install-recommends libtinfo5 # LLVM dependencies on Ubuntu 20.04
        ;;
esac

# Bazel and related dependencies.
case $ARCH in
    'ppc64le' )
        BAZEL_LATEST="$(curl https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/latest/ 2>&1 \
          | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep '^bazel' | head -n 1)"
        curl -fSL https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/latest/${BAZEL_LATEST} \
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

function install_android_tools() {
    #############
    # Install JDK
    #############

    # Add Azul's public key
    apt-key adv \
        --keyserver hkp://keyserver.ubuntu.com:80 \
        --recv-keys 0xB1998361219BD9C9

    # Download and install the package that adds 
    # the Azul APT repository to the list of sources 
    curl -O https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb

    # Install the Java 8 JDK
    apt-get install -y ./zulu-repo_1.0.0-3_all.deb
    apt-get update -y
    apt-get install -y zulu8-jdk
    rm ./zulu-repo_1.0.0-3_all.deb

    #######################
    # Install Android tools
    #######################

    sdk_install_target="/github/home/.android"
    mkdir -p "$sdk_install_target/sdk"
    pushd "$sdk_install_target"

    cmdline_file="commandlinetools-linux-7583922_latest.zip"
    curl -OL "https://dl.google.com/android/repository/$cmdline_file"
    unzip "$cmdline_file"
    mkdir -p sdk/cmdline-tools/latest
    mv cmdline-tools/* sdk/cmdline-tools/latest

    ANDROID_HOME="$(realpath "$sdk_install_target/sdk")"
    SDKMANAGER=$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager

    echo "y" | $SDKMANAGER --install "ndk;21.4.7075529"
    $SDKMANAGER --install "platforms;android-30"
    $SDKMANAGER --install "build-tools;30.0.2"

    export "ANDROID_HOME=${ANDROID_HOME}"
    export "ANDROID_SDK_ROOT=${ANDROID_HOME}"
    export "ANDROID_NDK_HOME=${ANDROID_HOME}/ndk/21.4.7075529"

    popd
}

case $ARCH in
    'x86_64' )
        install_android_tools
        ;;
esac

source ./build_container_common.sh

# Soft link the gcc compiler (required by python env)
update-alternatives --install "/usr/bin/${ARCH}-linux-gnu-gcc" "${ARCH}-linux-gnu-gcc" "/usr/bin/${ARCH}-linux-gnu-gcc-9" 1

apt-get clean
