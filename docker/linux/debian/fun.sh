#!/bin/bash -e

set -o pipefail

# shellcheck source=docker/linux/common_fun.sh
. ./common_fun.sh

COMMON_PACKAGES=(
    apt-transport-https
    ca-certificates
    curl
    patch)
CI_PACKAGES=(git gosu sudo)
DEBIAN_PACKAGES=(
    aspell
    aspell-en
    byobu
    bzip2
    devscripts
    docker-buildx-plugin
    docker-ce-cli
    doxygen
    expect
    gdb
    git
    gnupg2
    gpg-agent
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
    zip
    yq)
DOCKER_PACKAGES=(
    containerd.io
    docker-buildx-plugin
    docker-ce
    docker-ce-cli
    docker-compose-plugin
    expect
    gettext
    jq
    netcat-openbsd
    skopeo
    whois
    yq)
GROUP_ID="${GROUP_ID:-${USER_ID:-1000}}"
USER_ID="${USER_ID:-1000}"
USER_NAME="${USER_NAME:-envoybuild}"
WORKER_PACKAGES=(autoconf automake libtool m4)

add_apt_key() {
    local key_url="$1"
    local key_id="$2"
    local key_path="/usr/share/keyrings/${key_id}.gpg"

    echo "Add apt key(${key_id}): ${key_url}" >&2
    wget -qO - "$key_url" | gpg --dearmor | sudo tee "$key_path" > /dev/null
    echo -n "$key_path"
}

add_apt_repos () {
    local repo

    apt-get update -y
    apt-get -qq install -y ca-certificates
    for repo in "${@}"; do
        echo "deb ${repo}" >> "/etc/apt/sources.list"
    done
    cat /etc/apt/sources.list
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

    # Workaround https://github.com/llvm/llvm-project/issues/75490
    curl -LO "http://deb.debian.org/debian/pool/main/n/ncurses/libtinfo5_6.4-4_${DEB_ARCH}.deb"
    dpkg -i "libtinfo5_6.4-4_${DEB_ARCH}.deb"
    rm "libtinfo5_6.4-4_${DEB_ARCH}.deb"

    # Workaround for https://github.com/llvm/llvm-project/issues/113696
    if [[ "$DEB_ARCH" == "arm64" ]]; then
        WORKER_PACKAGES+=(libxml2)
    fi

    apt_install "${WORKER_PACKAGES[@]}"

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
    azul_keypath="$(add_apt_key https://repos.azul.com/azul-repo.key azul)"
    echo "deb [signed-by=${azul_keypath}] https://repos.azul.com/zulu/deb stable main" \
        | sudo tee /etc/apt/sources.list.d/zulu.list
    mobile_install_jdk
    mobile_install_android
}

install_devel () {
    # Install development tools (no system compilers - toolchains will provide these)
    echo "Installing development tools..."
    apt-get -qq update -y
    apt-get -qq install -y --no-install-recommends "${DEBIAN_PACKAGES[@]}"
    apt-get -qq update
    apt-get -qq upgrade -y

    apt_install "${DEV_PACKAGES[@]}"
    apt-get -qq dist-upgrade -y
    install_gcc

    # not sure if this is necessary
    export NO_INSTALL_BUILDTOOLS=1
    install_build

    echo "Development tools installation completed - compilers provided by toolchains"
}

install () {
    apt-get -qq update -y
    apt-get -qq install -y --no-install-recommends "${CI_PACKAGES[@]}"
    create_user
}

install_gcc () {
    apt-get -qq update -y
    apt-get -qq install -y g++-13
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 1
}

install_bazelisk () {
    apt-get -qq update
    apt-get -qq install -y --no-install-recommends wget
    install_build_tools
}

install_docker () {
    apt-get -qq update -y
    apt-get -qq install -y --no-install-recommends gpg locales lsb-release wget
    if ! locale -a | grep -q en_US.utf8; then
        localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
    fi
    lsb_release="$(lsb_release -cs)"
    docker_key=$(add_apt_key "${APT_KEY_DOCKER}" docker)
    k8s_key=$(add_apt_key "${APT_KEY_K8S}" k8s)
    apt_repos=(
        "[arch=${DEB_ARCH} signed-by=${docker_key}] https://download.docker.com/linux/debian ${lsb_release} stable"
        "[signed-by=${k8s_key}] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_Testing/ /")
    add_apt_repos "${apt_repos[@]}"
    apt-get -qq update
    apt-get -qq install -y --no-install-recommends "${DOCKER_PACKAGES[@]}"
    apt-get -qq update
    apt-get -qq upgrade -y
}

install_llvm () {
    apt-get update -qq
    apt-get install --no-install-recommends -y -qq curl xz-utils
    mkdir /tmp/llvm
    mkdir /opt/llvm
    cd /tmp/llvm
    curl -sL --output llvm.tar.xz "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-${LLVM_DISTRO}.tar.xz"
    tar Jxf llvm.tar.xz --strip-components=1 -C /opt/llvm
    LLVM_HOST_TARGET="$(/opt/llvm/bin/llvm-config --host-target)"
    echo "/opt/llvm/lib/${LLVM_HOST_TARGET}" > /etc/ld.so.conf.d/llvm.conf
    rm -rf /tmp/llvm
}

create_user () {
    groupadd -g "$GROUP_ID" "$USER_NAME"
    useradd \
        -u "$USER_ID" \
        -g "$GROUP_ID" \
        -m -d "/home/$USER_NAME" \
        -s /bin/bash \
        "$USER_NAME"
}

stamp_build () {
    local container_name="$1" container_tag="$2"
    echo "Stamping ${container_name}-${container_tag} > .build-id"
    echo "${container_name}-${container_tag}" > /.build-id
}
