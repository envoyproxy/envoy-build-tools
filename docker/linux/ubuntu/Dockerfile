FROM ubuntu:focal@sha256:33a5cc25d22c45900796a1aca487ad7a7cb09f09ea00b779e3b2026b4fc2faba as env
ARG ANDROID_CLI_TOOLS=https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip \
    APT_KEY_DEADSNAKES=F23C5A6CF475977595C89F51BA6932366A755776 \
    APT_KEY_TOOLCHAIN=60C317803A41BA51845E371A1E9377A2BA9EF27F \
    APT_KEY_AZUL=0xB1998361219BD9C9 \
    BAZELISK_SHA256SUM=ce52caa51ef9e509fb6b7e5ad892e5cf10feb0794b0aed4d2f36adb00a1a2779 \
    BAZELISK_SHA256SUM_ARM64=6070bf70915e92b3a5ce8eee6f4a8a0968bb350be2a98b80b0fd2fc13ce8a254 \
    BAZELISK_VERSION=1.18.0 \
    CLANG_TOOLS_SHA256SUM=f49de4b4502a6608425338e2d93bbe4529cac0a22f2dc1c119ef175a4e1b5bf0 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.utf8 \
    LCOV_VERSION=1.15 \
    LCOV_SHA256SUM=c1cda2fa33bec9aa2c2c73c87226cfe97de0831887176b45ee523c5e30f8053a \
    LLVM_DISTRO=x86_64-linux-gnu-ubuntu-18.04 \
    LLVM_DISTRO_ARM64=aarch64-linux-gnu \
    LLVM_DISTRO_PPC64LE=powerpc64le-linux-ubuntu-18.04 \
    LLVM_DOWNLOAD_PREFIX=https://github.com/llvm/llvm-project/releases/download/llvmorg- \
    LLVM_SHA256SUM=38bc7f5563642e73e69ac5626724e206d6d539fbef653541b34cae0ba9c3f036 \
    LLVM_SHA256SUM_ARM64=8ca4d68cf103da8331ca3f35fe23d940c1b78fb7f0d4763c1c059e352f5d1bec \
    LLVM_SHA256SUM_PPC64LE=7fc9f07ff0fcf191df93fe4adc1da555e43f62fe1d3ddafb15c943f72b1bda17 \
    LLVM_VERSION=15.0.6 \
    ZULU_INSTALL_DEB=https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb
ENV LANG=$LANG
SHELL ["/bin/bash", "-c"]
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
