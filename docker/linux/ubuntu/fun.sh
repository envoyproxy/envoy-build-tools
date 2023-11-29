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
APT_REPOS_LLVM=(
    "https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main")
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
    g++
    git
    gnupg2
    gpg-agent
    unzip
    wget
    xz-utils)
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
LLVM_PACKAGES=(
    cmake
    cmake-data
    ninja-build
    python3)
UBUNTU_PACKAGES=(
    automake
    bc
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


if [[ "$ARCH" == "aarch64" ]]; then
    COMMON_PACKAGES+=(libtinfo5)
fi


# This is not currently used
add_ubuntu_keys () {
    apt-get update -y
    for key in "${@}"; do
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$key"
    done
}

add_apt_key () {
    apt-get update -y
    wget -q -O - "$1" > /etc/apt/trusted.gpg.d/"$2"
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

install_base () {
    apt_install "${COMMON_PACKAGES[@]}"
    add_ubuntu_keys "${APT_KEYS_ENV[@]}"
    add_apt_repos "${APT_REPOS_ENV[@]}"
    apt-get -qq update
    apt-get -qq dist-upgrade -y
    ensure_stdlibcc
}

install_gn (){
    # Install gn tools which will be used for building wee8
    wget -q -O gntool.zip "https://chrome-infra-packages.appspot.com/dl/gn/gn/linux-${DEB_ARCH}/+/latest"
    unzip -q gntool.zip -d gntool
    cp gntool/gn /usr/local/bin/gn
    chmod +x /usr/local/bin/gn
    rm -rf gntool*
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
    echo "y" | $sdkmanager --install "ndk;${ANDROID_NDK_VERSION}" | grep -v = || true
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
    if [[ "$ARCH" == "ppc64le" ]]; then
        install_ppc64le_bazel
    fi
    add_apt_key "${APT_KEY_DOCKER}" "docker.asc"
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
    add_apt_key "${APT_KEY_KITWARE}" "kitware.asc"
    add_apt_repos "${APT_REPOS_LLVM[@]}"
    apt-get -qq update -y
    apt-get -qq install -y --no-install-recommends "${LLVM_PACKAGES[@]}"
    install_llvm_bins
    install_san
    install_gn
}
