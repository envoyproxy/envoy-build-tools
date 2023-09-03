#!/bin/bash -e

set -o pipefail

# shellcheck source=docker/linux/common_fun.sh
. ./common_fun.sh


LSB_RELEASE="$(lsb_release -cs)"
APT_REPOS=(
    "http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu  ${LSB_RELEASE} main"
    "[arch=${DEB_ARCH}] https://download.docker.com/linux/ubuntu ${LSB_RELEASE} stable"
    "http://ppa.launchpad.net/deadsnakes/ppa/ubuntu ${LSB_RELEASE} main")
COMMON_PACKAGES=(
    apt-transport-https
    ca-certificates
    g++
    gpg-agent
    lsb-release
    unzip
    wget
    xz-utils)
LLVM_PACKAGES=(
    cmake
    cmake-data
    ninja-build
    python3)
UBUNTU_PACKAGES=(
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


if [[ "$ARCH" == "aarch64" ]]; then
    COMMON_PACKAGES+=(libtinfo5)
fi


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

setup_locales () {
    apt_install locales
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
}

install_base () {
    setup_locales
    apt_install "${COMMON_PACKAGES[@]}"
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
    cmdline_file="commandlinetools-linux-7583922_latest.zip"
    wget -q "https://dl.google.com/android/repository/$cmdline_file"
    unzip -q "$cmdline_file"
    mkdir -p sdk/cmdline-tools/latest
    mv cmdline-tools/* sdk/cmdline-tools/latest
    sdkmanager=$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager
    echo "y" | $sdkmanager --install "ndk;$ANDROID_NDK_VERSION"
    $sdkmanager --install "platforms;android-30"
    $sdkmanager --install "build-tools;30.0.2"
}

mobile_install_jdk () {
    # Add Azul's public key
    apt-key adv \
            --keyserver hkp://keyserver.ubuntu.com:80 \
            --recv-keys 0xB1998361219BD9C9
    # Download and install the package that adds
    # the Azul APT repository to the list of sources
    wget -q https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb
    # Install the Java 8 JDK
    apt-get install -y ./zulu-repo_1.0.0-3_all.deb
    apt-get update -y
    apt-get install -y zulu8-jdk
    rm ./zulu-repo_1.0.0-3_all.deb
}

mobile_install () {
    mobile_install_jdk
    mobile_install_android
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

install () {
    if [[ "$ARCH" == "ppc64le" ]]; then
        install_ppc64le_bazel
    fi
    add_apt_keys
    add_apt_repos "${APT_REPOS[@]}"
    apt-get install -y --no-install-recommends "${UBUNTU_PACKAGES[@]}"
    setup_python
    install_build
}

install_llvm () {
    apt-get -qq update -y
    apt-get -qq install -y --no-install-recommends "${LLVM_PACKAGES[@]}"
    install_llvm_bins
    install_san
    install_gn
}
