#!/bin/bash -e

if [[ "$(uname -m)" == "x86_64" ]]; then
  # buildozer
  VERSION=0.29.0
  SHA256=2a5c3e3390de07248704f21ed38495062fb623c9b0aef37deda257a917891ea6
  curl --location --output /usr/local/bin/buildozer https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildozer \
    && echo "$SHA256  /usr/local/bin/buildozer" | sha256sum --check \
    && chmod +x /usr/local/bin/buildozer

  # buildifier
  VERSION=0.29.0
  SHA256=4c985c883eafdde9c0e8cf3c8595b8bfdf32e77571c369bf8ddae83b042028d6
  curl --location --output /usr/local/bin/buildifier https://github.com/bazelbuild/buildtools/releases/download/"$VERSION"/buildifier \
    && echo "$SHA256  /usr/local/bin/buildifier" | sha256sum --check \
    && chmod +x /usr/local/bin/buildifier

  # bazelisk
  VERSION=1.0
  SHA256=820f1432bb729cf1d51697a64ce57c0cff7ea4013acaf871b8c24b6388174d0d
  curl --location --output /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v${VERSION}/bazelisk-linux-amd64 \
    && echo "$SHA256  /usr/local/bin/bazel" | sha256sum --check \
    && chmod +x /usr/local/bin/bazel
fi
