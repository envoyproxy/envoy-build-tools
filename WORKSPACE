workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "89a053218639b1c5e3589a859bb310e0a402dedbe4ee369560e66026ae5ef1f2",
    strip_prefix = "bazel-toolchains-3.5.0",
    urls = ["https://github.com/bazelbuild/bazel-toolchains/releases/download/3.5.0/bazel-toolchains-3.5.0.tar.gz"],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()

load("//toolchains:rbe_toolchains_config.bzl", "rbe_toolchains_config")

rbe_toolchains_config(generator = True)
