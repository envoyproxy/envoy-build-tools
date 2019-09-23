workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "a1e273b6159ae858f53046f5bab9678cffa82a72f0bf0c0a9e4af8fddb91209c",
    strip_prefix = "bazel-toolchains-0.29.6",
    urls = [
        "https://github.com/bazelbuild/bazel-toolchains/releases/download/0.29.6/bazel-toolchains-0.29.6.tar.gz",
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-toolchains/archive/0.29.6.tar.gz",
    ],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()

load("//toolchains:rbe_toolchains_config.bzl", "rbe_toolchains_config")

rbe_toolchains_config(generator = True)
