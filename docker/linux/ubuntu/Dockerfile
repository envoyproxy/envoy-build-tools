FROM ubuntu:focal@sha256:33a5cc25d22c45900796a1aca487ad7a7cb09f09ea00b779e3b2026b4fc2faba as env
ARG APT_KEY_DEADSNAKES=F23C5A6CF475977595C89F51BA6932366A755776 \
    APT_KEY_TOOLCHAIN=60C317803A41BA51845E371A1E9377A2BA9EF27F \
    BAZELISK_SHA256SUM=ce52caa51ef9e509fb6b7e5ad892e5cf10feb0794b0aed4d2f36adb00a1a2779 \
    BAZELISK_SHA256SUM_ARM64=6070bf70915e92b3a5ce8eee6f4a8a0968bb350be2a98b80b0fd2fc13ce8a254 \
    BAZELISK_VERSION=1.18.0 \
    BUILD_TOOLS_VERSION=5.1.0 \
    BUILDIFIER_SHA256SUM=52bf6b102cb4f88464e197caac06d69793fa2b05f5ad50a7e7bf6fbd656648a3 \
    BUILDIFIER_SHA256SUM_ARM64=917d599dbb040e63ae7a7e1adb710d2057811902fdc9e35cce925ebfd966eeb8 \
    BUILDOZER_SHA256SUM=7346ce1396dfa9344a5183c8e3e6329f067699d71c4391bd28317391228666bf \
    BUILDOZER_SHA256SUM_ARM64=0b08e384709ec4d4f5320bf31510d2cefe8f9e425a6565b31db06b2398ff9dc4 \
    CLANG_TOOLS_SHA256SUM=f49de4b4502a6608425338e2d93bbe4529cac0a22f2dc1c119ef175a4e1b5bf0 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.utf8 \
    LCOV_VERSION=1.15 \
    LCOV_SHA256SUM=c1cda2fa33bec9aa2c2c73c87226cfe97de0831887176b45ee523c5e30f8053a \
    LLVM_DISTRO=x86_64-linux-gnu-ubuntu-18.04 \
    LLVM_DISTRO_ARM64=aarch64-linux-gnu \
    LLVM_DISTRO_PPC64LE=powerpc64le-linux-ubuntu-18.04 \
    LLVM_DOWNLOAD_PREFIX=https://github.com/llvm/llvm-project/releases/download/llvmorg- \
    LLVM_SHA256SUM=61582215dafafb7b576ea30cc136be92c877ba1f1c31ddbbd372d6d65622fef5 \
    LLVM_SHA256SUM_ARM64=1792badcd44066c79148ffeb1746058422cc9d838462be07e3cb19a4b724a1ee \
    LLVM_SHA256SUM_PPC64LE=2d504c4920885c86b306358846178bc2232dfac83b47c3b1d05861a8162980e6 \
    LLVM_VERSION=14.0.0
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