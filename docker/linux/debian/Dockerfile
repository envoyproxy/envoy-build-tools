FROM debian:bullseye-slim@sha256:779034981fec838da124ff6ab9211499ba5d4e769dabdfd6c42c6ae2553b9a3b AS worker-base
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-ec"]
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && install_base


FROM worker-base AS bazelisk
ARG BAZELISK_SHA256SUM=6539c12842ad76966f3d493e8f80d67caa84ec4a000e220d5459833c967c12bc \
    BAZELISK_SHA256SUM_ARM64=54f85ef4c23393f835252cc882e5fea596e8ef3c4c2056b059f8067cd19f0351 \
    BAZELISK_VERSION=1.26.0
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && install_bazelisk \
    && stamp_build bazelisk "$CONTAINER_TAG"


FROM worker-base AS ci-base
ARG USER_NAME \
    USER_ID \
    GROUP_ID
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && install
COPY --from=bazelisk /usr/local/bin/bazel /usr/local/bin/bazel
COPY debian/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]


FROM ci-base AS devtools-base
ARG BAZELISK_SHA256SUM=6539c12842ad76966f3d493e8f80d67caa84ec4a000e220d5459833c967c12bc \
    BAZELISK_SHA256SUM_ARM64=54f85ef4c23393f835252cc882e5fea596e8ef3c4c2056b059f8067cd19f0351 \
    BAZELISK_VERSION=1.26.0 \
    APT_KEY_K8S=https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/Debian_12/Release.key \
    APT_KEY_DOCKER=https://download.docker.com/linux/debian/gpg
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && install_devel


FROM ci-base AS docker-base
ARG APT_KEY_K8S=https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/Debian_12/Release.key \
    APT_KEY_DOCKER=https://download.docker.com/linux/debian/gpg
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && install_docker
COPY debian/docker-entrypoint.sh /entrypoint.sh


FROM devtools-base AS llvm-base
ARG LLVM_VERSION=18.1.8 \
    LLVM_DISTRO=ubuntu-18.04
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && install_llvm
COPY debian/llvm-entrypoint.sh /entrypoint.sh


FROM devtools-base AS test
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/debian/test.sh,target=/debian/test.sh \
    ./debian/test.sh
COPY \
    ./debian/buildifier \
    ./debian/buildozer \
    /usr/local/bin


# mobile
FROM llvm-base AS mobile-base
ARG ANDROID_CLI_TOOLS=https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip \
    APT_KEY_AZUL=0xB1998361219BD9C9 \
    ZULU_INSTALL_DEB=https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb
ENV ANDROID_HOME=/.android/sdk \
    ANDROID_NDK_HOME=/.android/sdk/ndk/26.3.11579264 \
    ANDROID_NDK_VERSION=26.3.11579264 \
    ANDROID_SDK_INSTALL_TARGET=/.android \
    ANDROID_SDK_ROOT=/.android/sdk
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && mobile_install


# Stamp containers
FROM worker-base AS worker
ARG CONTAINER_TAG
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && stamp_build worker "$CONTAINER_TAG"

FROM docker-base AS docker
ARG CONTAINER_TAG
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && stamp_build docker "$CONTAINER_TAG"

FROM devtools-base AS devtools
ARG CONTAINER_TAG
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && stamp_build devtools "$CONTAINER_TAG"

FROM llvm-base AS llvm
ARG CONTAINER_TAG
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && stamp_build llvm "$CONTAINER_TAG"

FROM mobile-base AS mobile
ARG CONTAINER_TAG
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && stamp_build mobile "$CONTAINER_TAG"

FROM ci-base AS ci
ARG CONTAINER_TAG
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && stamp_build ci "$CONTAINER_TAG"

FROM ci
