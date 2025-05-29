FROM ubuntu:focal@sha256:8feb4d8ca5354def3d8fce243717141ce31e2c428701f6682bd2fafe15388214 AS env
ARG ANDROID_CLI_TOOLS=https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip \
    APT_KEY_TOOLCHAIN=60C317803A41BA51845E371A1E9377A2BA9EF27F \
    APT_KEY_AZUL=0xB1998361219BD9C9 \
    APT_KEY_K8S=https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_20.04/Release.key \
    APT_KEY_KITWARE=https://apt.kitware.com/keys/kitware-archive-latest.asc \
    APT_KEY_DOCKER=https://download.docker.com/linux/ubuntu/gpg \
    BAZELISK_SHA256SUM=ce52caa51ef9e509fb6b7e5ad892e5cf10feb0794b0aed4d2f36adb00a1a2779 \
    BAZELISK_SHA256SUM_ARM64=6070bf70915e92b3a5ce8eee6f4a8a0968bb350be2a98b80b0fd2fc13ce8a254 \
    BAZELISK_VERSION=1.18.0 \
    CLANG_TOOLS_SHA256SUM=e58877fcd95ed106824bd1a31276dd17ed0c53adcd60ca75289eac0654f0a7f1 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.utf8 \
    LIBSTDCXX_EXPECTED_VERSION=13.1 \
    LLVM_DISTRO=x86_64-linux-gnu-ubuntu-18.04 \
    LLVM_DISTRO_ARM64=aarch64-linux-gnu \
    LLVM_DOWNLOAD_PREFIX=https://github.com/llvm/llvm-project/releases/download/llvmorg- \
    LLVM_SHA256SUM=54ec30358afcc9fb8aa74307db3046f5187f9fb89fb37064cdde906e062ebf36 \
    LLVM_SHA256SUM_ARM64=dcaa1bebbfbb86953fdfbdc7f938800229f75ad26c5c9375ef242edad737d999 \
    LLVM_VERSION=18.1.8 \
    ZULU_INSTALL_DEB=https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb
ENV LANG=$LANG
SHELL ["/bin/bash", "-ec"]
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/ubuntu/fun.sh,target=/ubuntu/fun.sh \
    . ./ubuntu/fun.sh \
    && install_base


FROM env AS llvm
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/ubuntu/fun.sh,target=/ubuntu/fun.sh \
    . ./ubuntu/fun.sh \
    && install_llvm


FROM env AS ci
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/ubuntu/fun.sh,target=/ubuntu/fun.sh \
    . ./ubuntu/fun.sh \
    && install_ci


FROM ci AS full
COPY --from=llvm /opt /opt
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/ubuntu/fun.sh,target=/ubuntu/fun.sh \
    . ./ubuntu/fun.sh \
    && install


FROM full AS test
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/ubuntu/test.sh,target=/ubuntu/test.sh \
    ./ubuntu/test.sh
COPY \
    ./ubuntu/buildifier \
    ./ubuntu/buildozer \
    /usr/local/bin


# mobile
FROM full AS mobile
ENV ANDROID_HOME=/.android/sdk \
    ANDROID_NDK_HOME=/.android/sdk/ndk/26.3.11579264 \
    ANDROID_NDK_VERSION=26.3.11579264 \
    ANDROID_SDK_INSTALL_TARGET=/.android \
    ANDROID_SDK_ROOT=/.android/sdk
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/ubuntu/fun.sh,target=/ubuntu/fun.sh \
    . ./ubuntu/fun.sh \
    && mobile_install


FROM full
