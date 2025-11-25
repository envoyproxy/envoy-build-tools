# Create equivs packages to prevent installation of GCC when installing libtool
FROM debian:trixie-slim@sha256:66b37a5078a77098bfc80175fb5eb881a3196809242fd295b25502854e12cbec AS fake
SHELL ["/bin/bash", "-ec"]
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && build_fake_compiler


FROM debian:trixie-slim@sha256:66b37a5078a77098bfc80175fb5eb881a3196809242fd295b25502854e12cbec AS worker-base
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-ec"]
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    --mount=type=bind,from=fake,source=/tmp/fake-compiler,target=/tmp/fake-compiler \
    . ./debian/fun.sh \
    && install_base


FROM worker-base AS bazelisk
ARG BAZELISK_SHA256SUM=6539c12842ad76966f3d493e8f80d67caa84ec4a000e220d5459833c967c12bc \
    BAZELISK_SHA256SUM_ARM64=54f85ef4c23393f835252cc882e5fea596e8ef3c4c2056b059f8067cd19f0351 \
    BAZELISK_VERSION=1.26.0
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && install_bazelisk


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


# This can be removed if/when we implement hermetic gcc toolchains
FROM worker-base AS gcc-base
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && install_gcc


FROM ci-base AS docker-base
ARG APT_KEY_K8S=https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/Debian_Testing/Release.key \
    APT_KEY_DOCKER=https://download.docker.com/linux/debian/gpg
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && install_docker
COPY debian/docker-entrypoint.sh /entrypoint.sh


FROM docker-base AS devtools-base
RUN --mount=type=tmpfs,target=/var/cache/apt \
    --mount=type=tmpfs,target=/var/lib/apt/lists \
    --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && install_devel


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
FROM devtools-base AS mobile-base
ARG ANDROID_CLI_TOOLS=https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip \
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
ENTRYPOINT []


# Stamp containers
FROM worker-base AS worker
ARG CONTAINER_TAG
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && stamp_build worker "$CONTAINER_TAG"

FROM gcc-base AS gcc
ARG CONTAINER_TAG
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/debian/fun.sh,target=/debian/fun.sh \
    . ./debian/fun.sh \
    && stamp_build gcc "$CONTAINER_TAG"

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
