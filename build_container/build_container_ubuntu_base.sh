#!/bin/bash -e

set -o pipefail

ARCH="$(uname -m)"
COMMON_PACKAGES=(
    apt-transport-https
    ca-certificates
    g++
    gpg-agent
    lsb-release
    unzip
    wget
    xz-utils)


if [[ "${ARCH}" == "aarch64" ]]; then
    COMMON_PACKAGES+=(libtinfo5)
fi

apt_install () {
    apt-get -qq update -y
    apt-get -qq install -y --no-install-recommends --no-install-suggests "${@}"
}

setup_locales () {
    apt_install locales
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
}

setup_locales
apt_install "${COMMON_PACKAGES[@]}"
