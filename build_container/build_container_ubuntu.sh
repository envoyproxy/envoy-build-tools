#!/bin/bash

set -e

# NB: The apt repository keys that are setup here can expire
#   For this reason it is generally good to ensure that the image is
#   updated every few months, to ensure ~fresh keys.

ARCH="$(uname -m)"
LSB_RELEASE="$(lsb_release -cs)"

# gdb
add-apt-repository -y ppa:ubuntu-toolchain-r/test

# docker-ce-cli
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
case $ARCH in
    'ppc64le' )
        DEB_ARCH=ppc64le
        ;;
    'x86_64' )
        DEB_ARCH=amd64
        ;;
    'aarch64' )
        DEB_ARCH=arm64
        ;;
esac

add-apt-repository "deb [arch=${DEB_ARCH}] https://download.docker.com/linux/ubuntu ${LSB_RELEASE} stable"

# Python
add-apt-repository ppa:deadsnakes/ppa

apt-get update -y

PACKAGES=(
    aspell
    aspell-en
    automake
    bc
    bzip2
    devscripts
    docker-ce-cli
    doxygen
    expect
    gdb
    git
    gnupg2
    graphviz
    jq
    libffi-dev
    libncurses-dev
    libtool
    make
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

setup_python () {
    # Get pip for python3.10
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

    # make python3.10 the default python3 interpreter
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

    # pip installs
    # TODO(phlax): use hashed requirements
    pip3 install --no-cache-dir -U pyyaml virtualenv
}

if [[ "$ARCH" == "ppc64le" ]]; then
    BAZEL_LATEST="$(curl https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/latest/ 2>&1 \
          | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep '^bazel' | head -n 1)"
    curl -fSL "https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/latest/${BAZEL_LATEST}" \
         -o /usr/local/bin/bazel
    chmod +x /usr/local/bin/bazel
fi

setup_python
source ./build_container_common.sh
install_build
