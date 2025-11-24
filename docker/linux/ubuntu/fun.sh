#!/bin/bash -e

set -o pipefail

# shellcheck source=docker/linux/common_fun.sh
. ./common_fun.sh


if ! command -v lsb_release &> /dev/null; then
    apt-get -qq update -y
    apt-get -qq install -y --no-install-recommends locales
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
    apt-get -qq update -y
    apt-get -qq install -y --no-install-recommends lsb-release
fi


LSB_RELEASE="$(lsb_release -cs)"
APT_KEYS_ENV=(
    "${APT_KEY_TOOLCHAIN}")
APT_KEYS_MOBILE=(
    "$APT_KEY_AZUL")
APT_REPOS_ENV=(
    "http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu  ${LSB_RELEASE} main")
APT_REPOS=(
    "[arch=${DEB_ARCH}] https://download.docker.com/linux/ubuntu ${LSB_RELEASE} stable"
    "http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /")
COMMON_PACKAGES=(
    apt-transport-https
    ca-certificates
    gnupg2
    gpg-agent
    libnuma-dev
    libtinfo5
    unzip
    wget
    xz-utils)
DEV_PACKAGES=(
    g++-13
    git)
CI_PACKAGES=(
    aspell
    aspell-en
    jq
    libcap2-bin
    make
    patch
    tcpdump
    time
    sudo)
UBUNTU_PACKAGES=(
    autoconf-archive
    automake
    byobu
    bzip2
    curl
    devscripts
    docker-buildx-plugin
    docker-ce-cli
    doxygen
    expect
    gdb
    graphviz
    libffi-dev
    libncurses-dev
    libssl-dev
    libtool
    make
    rpm
    rsync
    skopeo
    ssh-client
    strace
    tshark
    zip)


# This is not currently used
add_ubuntu_keys () {
    apt-get update -y
    for key in "${@}"; do
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$key"
    done
}

add_apt_key () {
    apt-get update -y
    wget -q -O - "$1" | apt-key add -
}

add_apt_k8s_key () {
    apt-get update -y
    wget -q -O - "$1" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/devel_kubic_libcontainers_stable.gpg > /dev/null
}

add_apt_repos () {
    local repo
    apt-get update -y
    apt-get -qq install -y ca-certificates
    for repo in "${@}"; do
        echo "deb ${repo}" >> "/etc/apt/sources.list"
    done
    apt-get update -y
}

apt_install () {
    apt-get -qq update -y
    apt-get -qq install -y --no-install-recommends --no-install-suggests "${@}"
}

ensure_stdlibcc () {
    apt list libstdc++6 | grep installed | grep "$LIBSTDCXX_EXPECTED_VERSION"
}

configure_dns_fast_fail () {
    # Configure DNS to fail fast for non-existent domains
    # This mitigates systemd-resolved timeout issues in recent Ubuntu updates
    # where DNS queries for non-existent domains timeout instead of failing immediately
    
    # In Docker containers, we need to configure /etc/resolv.conf with fast-fail options
    # The options timeout:N and attempts:N control DNS resolution behavior:
    # - timeout: seconds to wait for a response before trying next server (default 5)
    # - attempts: number of times to try each nameserver (default 2)
    #
    # NOTE: timeout:1 attempts:1 is aggressive but necessary for tests that expect
    # immediate failure for non-existent domains. This prevents CI timeouts.
    
    # Check if /etc/resolv.conf exists and is writable
    if [ -f /etc/resolv.conf ]; then
        # Remove the file if it's a symlink to allow us to create a real file
        if [ -L /etc/resolv.conf ]; then
            # Preserve the current content before removing the symlink
            local temp_resolv
            temp_resolv=$(mktemp -m 600)
            cat /etc/resolv.conf > "$temp_resolv" 2>/dev/null || true
            rm -f /etc/resolv.conf
            cat "$temp_resolv" > /etc/resolv.conf
            rm -f "$temp_resolv"
        fi
        
        # Add DNS timeout options if not already present
        if ! grep -q "^options" /etc/resolv.conf 2>/dev/null; then
            # Insert options line at the beginning for faster DNS failure
            sed -i '1i options timeout:1 attempts:1' /etc/resolv.conf
        else
            # Options line exists, check if we need to add timeout or attempts
            if ! grep -q "^options.*timeout" /etc/resolv.conf 2>/dev/null; then
                sed -i '/^options/ s/$/ timeout:1/' /etc/resolv.conf
            fi
            if ! grep -q "^options.*attempts" /etc/resolv.conf 2>/dev/null; then
                sed -i '/^options/ s/$/ attempts:1/' /etc/resolv.conf
            fi
        fi
    fi
}

install_base () {
    apt_install "${COMMON_PACKAGES[@]}"
    add_ubuntu_keys "${APT_KEYS_ENV[@]}"
    add_apt_repos "${APT_REPOS_ENV[@]}"
    apt-get -qq update
    apt_install "${DEV_PACKAGES[@]}"
    apt-get -qq dist-upgrade -y
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 1
    ensure_stdlibcc
    configure_dns_fast_fail
}

mobile_install_android () {
    mkdir -p "$ANDROID_HOME"
    cd "$ANDROID_SDK_INSTALL_TARGET"
    wget -q -O android-tools.zip "${ANDROID_CLI_TOOLS}"
    unzip -q android-tools.zip
    rm android-tools.zip
    mkdir -p sdk/cmdline-tools/latest
    mv cmdline-tools/* sdk/cmdline-tools/latest
    sdkmanager="${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager"
    (yes || :) | $sdkmanager --licenses
    $sdkmanager --install "ndk;${ANDROID_NDK_VERSION}" | (grep -v = || :)
    $sdkmanager --install "platforms;android-30" | grep -v = || true
    $sdkmanager --install "build-tools;30.0.2" | grep -v = || true
}

mobile_install_jdk () {
    # Download and install the package that adds
    # the Azul APT repository to the list of sources
    wget -q -O zulu.deb "${ZULU_INSTALL_DEB}"
    # Install the Java 11 JDK
    apt-get install -y ./zulu.deb
    apt-get update -y
    apt-get install -y zulu11-jdk
    rm ./zulu.deb
}

mobile_install () {
    add_ubuntu_keys "${APT_KEYS_MOBILE[@]}"
    mobile_install_jdk
    mobile_install_android
}

install () {
    add_apt_key "${APT_KEY_DOCKER}"
    add_apt_k8s_key "${APT_KEY_K8S}"
    add_apt_repos "${APT_REPOS[@]}"
    apt-get -qq update
    apt-get -qq install -y --no-install-recommends "${UBUNTU_PACKAGES[@]}"
    apt-get -qq update
    apt-get -qq upgrade -y
    ensure_stdlibcc
    LLVM_HOST_TARGET="$(/opt/llvm/bin/llvm-config --host-target)"
    echo "/opt/llvm/lib/${LLVM_HOST_TARGET}" > /etc/ld.so.conf.d/llvm.conf
    ldconfig
}

install_ci () {
    ensure_stdlibcc
    apt-get -qq update -y
    apt-get -qq install -y --no-install-recommends "${CI_PACKAGES[@]}"
    install_build
}

install_llvm () {
    install_llvm_bins
}
