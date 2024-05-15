FROM ubuntu:focal@sha256:33a5cc25d22c45900796a1aca487ad7a7cb09f09ea00b779e3b2026b4fc2faba as env
ARG ANDROID_CLI_TOOLS=https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip \
    APT_KEY_TOOLCHAIN=60C317803A41BA51845E371A1E9377A2BA9EF27F \
    APT_KEY_AZUL=0xB1998361219BD9C9 \
    APT_KEY_K8S=https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_20.04/Release.key \
    APT_KEY_KITWARE=https://apt.kitware.com/keys/kitware-archive-latest.asc \
    APT_KEY_DOCKER=https://download.docker.com/linux/ubuntu/gpg \
    BAZELISK_SHA256SUM=ce52caa51ef9e509fb6b7e5ad892e5cf10feb0794b0aed4d2f36adb00a1a2779 \
    BAZELISK_SHA256SUM_ARM64=6070bf70915e92b3a5ce8eee6f4a8a0968bb350be2a98b80b0fd2fc13ce8a254 \
    BAZELISK_VERSION=1.18.0 \
    CLANG_TOOLS_SHA256SUM=2cc806943af96f3391afc404765c936944a1fa441b752723c67fc3614f4f2ee7 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.utf8 \
    LCOV_VERSION=1.15 \
    LCOV_SHA256SUM=c1cda2fa33bec9aa2c2c73c87226cfe97de0831887176b45ee523c5e30f8053a \
    LIBSTDCXX_EXPECTED_VERSION=13.1 \
    LLVM_DISTRO=x86_64-linux-gnu-ubuntu-18.04 \
    LLVM_DISTRO_ARM64=aarch64-linux-gnu \
    LLVM_DISTRO_PPC64LE=powerpc64le-linux-ubuntu-18.04 \
    LLVM_DOWNLOAD_PREFIX=https://github.com/llvm/llvm-project/releases/download/llvmorg- \
    LLVM_SHA256SUM=1607375b4aa2aec490b6db51846a04b265675a87e925bcf5825966401ff9b0b1 \
    LLVM_SHA256SUM_ARM64=8c2f4d1606d24dc197a590acce39453abe7a302b9b92e762108f9b5a9701b1df \
    LLVM_SHA256SUM_PPC64LE=2d504c4920885c86b306358846178bc2232dfac83b47c3b1d05861a8162980e6 \
    LLVM_VERSION=18.1.4 \
    ZULU_INSTALL_DEB=https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb
ENV LANG=$LANG
SHELL ["/bin/bash", "-ec"]
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/ubuntu/fun.sh,target=/ubuntu/fun.sh \
    . ./ubuntu/fun.sh \
    && install_base


FROM env as llvm
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/ubuntu/fun.sh,target=/ubuntu/fun.sh \
    . ./ubuntu/fun.sh \
    && install_llvm


FROM env as ci
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/ubuntu/fun.sh,target=/ubuntu/fun.sh \
    . ./ubuntu/fun.sh \
    && install_ci


FROM ci as full
COPY --from=llvm /opt /opt
COPY --from=llvm \
    /usr/local/bin/gn \
    /usr/local/bin/gn
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/ubuntu/fun.sh,target=/ubuntu/fun.sh \
    . ./ubuntu/fun.sh \
    && install


FROM full as test
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/ubuntu/test.sh,target=/ubuntu/test.sh \
    ./ubuntu/test.sh
COPY \
    ./ubuntu/buildifier \
    ./ubuntu/buildozer \
    /usr/local/bin


# cmake/legacy (for 1.26 branch)
FROM full as cmake
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    curl -fsSL https://apt.kitware.com/keys/kitware-archive-latest.asc | apt-key add - \
    && echo "deb https://apt.kitware.com/ubuntu/ focal main" >> /etc/apt/sources.list \
    && apt-get -qq update -y \
    && apt-get -qq install --no-install-recommends cmake ninja-build


# mobile
FROM full as mobile
ENV ANDROID_HOME=/.android/sdk \
    ANDROID_NDK_HOME=/.android/sdk/ndk/21.4.7075529 \
    ANDROID_NDK_VERSION=21.4.7075529 \
    ANDROID_SDK_INSTALL_TARGET=/.android \
    ANDROID_SDK_ROOT=/.android/sdk
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/ubuntu/fun.sh,target=/ubuntu/fun.sh \
    . ./ubuntu/fun.sh \
    && mobile_install


FROM full
