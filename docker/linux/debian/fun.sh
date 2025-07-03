#!/bin/bash -e

set -o pipefail

# shellcheck source=docker/linux/common_fun.sh
. ./common_fun.sh


# Mobile and repo variables
APT_KEYS_MOBILE=(
    "$APT_KEY_AZUL")
COMMON_PACKAGES=(
    apt-transport-https
    ca-certificates
    libperl5.32
    libtinfo5
    patch)
DEV_PACKAGES=()
CI_PACKAGES=()
DEBIAN_PACKAGES=(
    aspell
    aspell-en
    byobu
    bzip2
    curl
    devscripts
    docker-buildx-plugin
    docker-ce-cli
    doxygen
    expect
    gdb
    git
    graphviz
    jq
    libcap2-bin
    libffi-dev
    libncurses-dev
    libssl-dev
    rpm
    rsync
    skopeo
    ssh-client
    strace
    sudo
    tcpdump
    time
    tshark
    unzip
    xz-utils
    zip)
GROUP_ID="${GROUP_ID:-${USER_ID:-1000}}"
USER_ID="${USER_ID:-1000}"
USER_NAME="${USER_NAME:-envoybuild}"


# This is used for mobile installs - we need to add the key properly
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
    wget -q -O - "$1" | gpg --dearmor > /etc/apt/trusted.gpg.d/devel_kubic_libcontainers_stable.gpg
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

install_base () {
    echo "Starting install_base for Debian slim image (${DEB_ARCH})..."

    # Install base packages first
    echo "Installing common packages..."
    apt_install "${COMMON_PACKAGES[@]}"

    # Note: No development tools installed in base layer
    # GCC, git, build-essential now installed in devel layer

    echo "Base installation completed - CI layer ready"
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

install_devel () {
    # Install development tools (no system compilers - toolchains will provide these)
    echo "Installing development tools..."

    apt-get -qq update -y
    apt-get -qq install -y --no-install-recommends locales lsb-release
    if ! locale -a | grep -q en_US.utf8; then
        localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
    fi
    LSB_RELEASE="$(lsb_release -cs)"
    APT_REPOS=(
        "[arch=${DEB_ARCH}] https://download.docker.com/linux/debian ${LSB_RELEASE} stable"
        "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_11/ /")

    apt-get -qq install -y --no-install-recommends wget gnupg2 gpg-agent software-properties-common
    add_apt_key "${APT_KEY_DOCKER}"
    add_apt_k8s_key "${APT_KEY_K8S}"
    add_apt_repos "${APT_REPOS[@]}"
    apt-get -qq update
    apt-get -qq install -y --no-install-recommends "${DEBIAN_PACKAGES[@]}"
    apt-get -qq update
    apt-get -qq upgrade -y

    install_build

    echo "Development tools installation completed - compilers provided by toolchains"
}

install () {
    apt-get -qq update -y
    apt-get -qq install -y --no-install-recommends "${CI_PACKAGES[@]}"
}

install_bazelisk() {
    apt-get -qq update
    apt-get -qq install -y --no-install-recommends wget
    install_build_tools
}

create_user() {
    groupadd -g "$GROUP_ID" "$USER_NAME"
    useradd \
        -u "$USER_ID" \
        -g "$GROUP_ID" \
        -m -d "/home/$USER_NAME" \
        -s /bin/bash \
        "$USER_NAME"
}

install_worker() {
    install_bazelisk
    create_user
}
