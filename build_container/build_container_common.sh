#!/bin/bash -e

function download_and_check () {
  local to=$1
  local url=$2
  local sha256=$3

  curl -fsSL --output "${to}" "${url}"
  echo "${sha256}  ${to}" | sha256sum --check
}

if [[ "$(uname -m)" == "x86_64" ]]; then
  # buildifier
  VERSION=5.1.0
  download_and_check /usr/local/bin/buildifier https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildifier-linux-amd64 \
    52bf6b102cb4f88464e197caac06d69793fa2b05f5ad50a7e7bf6fbd656648a3
  chmod +x /usr/local/bin/buildifier

  # buildozer
  download_and_check /usr/local/bin/buildozer https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildozer-linux-amd64 \
    7346ce1396dfa9344a5183c8e3e6329f067699d71c4391bd28317391228666bf
  chmod +x /usr/local/bin/buildozer

  # bazelisk
  VERSION=1.11.0
  download_and_check /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v${VERSION}/bazelisk-linux-amd64 \
    231ec5ca8115e94c75a1f4fbada1a062b48822ca04f21f26e4cb1cd8973cd458
  chmod +x /usr/local/bin/bazel
fi

if [[ "$(uname -m)" == "aarch64" ]]; then
  # buildifier
  VERSION=5.1.0
  download_and_check /usr/local/bin/buildifier https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildifier-linux-arm64 \
    917d599dbb040e63ae7a7e1adb710d2057811902fdc9e35cce925ebfd966eeb8
  chmod +x /usr/local/bin/buildifier

  # buildozer
  download_and_check /usr/local/bin/buildozer https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildozer-linux-arm64 \
    0b08e384709ec4d4f5320bf31510d2cefe8f9e425a6565b31db06b2398ff9dc4
  chmod +x /usr/local/bin/buildozer

  # bazelisk
  VERSION=1.11.0
  download_and_check /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v${VERSION}/bazelisk-linux-arm64 \
    f9119deb1eeb6d730ee8b2e1a14d09cb45638f0447df23144229c5b3b3bc2408
  chmod +x /usr/local/bin/bazel
fi

# Bazel and related dependencies.
if [[ "$(uname -m)" == "ppc64le" ]]; then
        BAZEL_LATEST="$(curl https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/latest/ 2>&1 \
          | sed -n 's/.*href="\([^"]*\).*/\1/p' | grep '^bazel' | head -n 1)"
        curl -fSL https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/latest/${BAZEL_LATEST} \
          -o /usr/local/bin/bazel
        chmod +x /usr/local/bin/bazel
fi
