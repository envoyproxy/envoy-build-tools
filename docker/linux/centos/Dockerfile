FROM centos:7@sha256:be65f488b7764ad3638f236b7b515b3678369a5124c47b8d32916d6487418ea4 as env
# SLES 11 has older glibc than CentOS 7, so pre-built binary for it works on CentOS 7
ARG BAZELISK_SHA256SUM=ce52caa51ef9e509fb6b7e5ad892e5cf10feb0794b0aed4d2f36adb00a1a2779 \
    BAZELISK_SHA256SUM_ARM64=6070bf70915e92b3a5ce8eee6f4a8a0968bb350be2a98b80b0fd2fc13ce8a254 \
    BAZELISK_VERSION=1.18.0 \
    BUILD_TOOLS_VERSION=5.1.0 \
    BUILDIFIER_SHA256SUM=52bf6b102cb4f88464e197caac06d69793fa2b05f5ad50a7e7bf6fbd656648a3 \
    BUILDIFIER_SHA256SUM_ARM64=917d599dbb040e63ae7a7e1adb710d2057811902fdc9e35cce925ebfd966eeb8 \
    BUILDOZER_SHA256SUM=7346ce1396dfa9344a5183c8e3e6329f067699d71c4391bd28317391228666bf \
    BUILDOZER_SHA256SUM_ARM64=0b08e384709ec4d4f5320bf31510d2cefe8f9e425a6565b31db06b2398ff9dc4 \
    LC_ALL=en_US.UTF-8 \
    LCOV_VERSION=1.15 \
    LCOV_SHA256SUM=c1cda2fa33bec9aa2c2c73c87226cfe97de0831887176b45ee523c5e30f8053a \
    LLVM_DISTRO=x86_64-linux-sles11.3 \
    LLVM_DISTRO_ARM64=aarch64-linux-gnu \
    LLVM_DOWNLOAD_PREFIX=https://github.com/llvm/llvm-project/releases/download/llvmorg- \
    LLVM_SHA256SUM=a7a3c2a7aff813bb10932636a6f1612e308256a5e6b5a5655068d5c5b7f80e86 \
    LLVM_SHA256SUM_ARM64=c2072390dc6c8b4cc67737f487ef384148253a6a97b38030e012c4d7214b7295 \
    LLVM_VERSION=10.0.0
ENV LC_ALL=$LC_ALL \
    PATH=/opt/rh/rh-git218/root/usr/bin:/opt/rh/devtoolset-7/root/usr/bin:/opt/llvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/centos/fun.sh,target=/centos/fun.sh \
    . ./centos/fun.sh \
    && install_base

FROM env as llvm
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/centos/fun.sh,target=/centos/fun.sh \
    . ./centos/fun.sh \
    && install_llvm

FROM env as base
COPY --from=llvm /opt /opt
COPY --from=llvm \
    /usr/local/bin/gn \
    /usr/local/bin/gn
RUN --mount=type=bind,source=/common_fun.sh,target=/common_fun.sh \
    --mount=type=bind,source=/centos/fun.sh,target=/centos/fun.sh \
    . ./centos/fun.sh \
    && install
