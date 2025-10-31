#!/bin/bash -e

set -o pipefail

ARCH="$(uname -m)"

DEB_ARCH=amd64
case $ARCH in
    'aarch64' )
        DEB_ARCH=arm64
        BAZELISK_SHA256SUM="$BAZELISK_SHA256SUM_ARM64"
        ;;
esac


download_and_check () {
    local to=$1
    local url=$2
    local sha256=$3
    echo "Download: ${url} -> ${to}"
    wget -q -O "${to}" "${url}"
    echo "${sha256}  ${to}" | sha256sum --check
}

install_build_tools () {
    download_and_check \
        /usr/local/bin/bazel \
        "https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-${DEB_ARCH}" \
        "${BAZELISK_SHA256SUM}"
    chmod +x /usr/local/bin/bazel
}

install_build () {
    setup_tcpdump
    if [[ -z "${NO_INSTALL_BUILDTOOLS}" ]]; then
        install_build_tools
    fi
    git config --global --add safe.directory /source
    mv ~/.gitconfig /etc/gitconfig
}

setup_tcpdump () {
    # Setup tcpdump for non-root - find tcpdump location dynamically
    local tcpdump_path
    tcpdump_path=$(which tcpdump 2>/dev/null || echo "")

    if [ -n "$tcpdump_path" ] && [ -f "$tcpdump_path" ]; then
        echo "Setting up tcpdump at $tcpdump_path for non-root access..."
        groupadd -r pcap
        chgrp pcap "$tcpdump_path"
        chmod 750 "$tcpdump_path"
        setcap cap_net_raw,cap_net_admin=eip "$tcpdump_path"
    else
        echo "ERROR: tcpdump not found in PATH after installation"
        exit 1
    fi
}
