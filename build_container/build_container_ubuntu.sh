#!/bin/bash

set -e

# NB: The apt repository keys that are setup here can expire
#   For this reason it is generally good to ensure that the image is
#   updated every few months, to ensure ~fresh keys.

ARCH="$(uname -m)"
LSB_RELEASE="$(lsb_release -cs)"

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

APT_REPOS=(
    "toolchain http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu  ${LSB_RELEASE} main"
    "docker [arch=${DEB_ARCH}] https://download.docker.com/linux/ubuntu ${LSB_RELEASE} stable"
    "python http://ppa.launchpad.net/deadsnakes/ppa/ubuntu ${LSB_RELEASE} main")

PACKAGES=(
    aspell
    aspell-en
    automake
    bc
    bzip2
    curl
    devscripts
    docker-ce-cli
    doxygen
    expect
    gdb
    git
    gnupg2
    gpg-agent
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
    zip)


add_apt_keys () {
    apt-get update -y
    apt-get -qq install -y --no-install-recommends gnupg2
    wget -q -O - https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    # deadsnakes
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "${APT_KEY_DEADSNAKES}"
    # toolchain
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "${APT_KEY_TOOLCHAIN}"
}

add_apt_repos () {
    apt-get update -y
    apt-get -qq install -y ca-certificates
    for repo in "${@}"; do
        name="$(echo "$repo" | cut -d' ' -f1)"
        data="$(echo "$repo" | cut -d' ' -f2-)"
        echo "deb ${data}" >> "/etc/apt/sources.list"
    done
    apt-get update -y
}

setup_python () {
    # Get pip for python3.10
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

    # make python3.10 the default python3 interpreter
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

    # pip installs
    # TODO(phlax): use hashed requirements
    pip3 install --no-cache-dir -U pyyaml virtualenv
}

install_ppc64le_bazel () {
    BAZEL_LATEST="$(curl https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/latest/ 2>&1 \
          | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep '^bazel' | head -n 1)"
    curl -fSL "https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/latest/${BAZEL_LATEST}" \
         -o /usr/local/bin/bazel
    chmod +x /usr/local/bin/bazel
}

install_ubuntu () {
    if [[ "$ARCH" == "ppc64le" ]]; then
        install_ppc64le_bazel
    fi
    add_apt_keys
    add_apt_repos "${APT_REPOS[@]}"
    apt-get install -y --no-install-recommends "${PACKAGES[@]}"
    setup_python
    source ./build_container_common.sh
    install_build
}

install_ubuntu
