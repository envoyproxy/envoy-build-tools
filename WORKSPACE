workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "5b6eef36e1f627bf739d3212487c7c31e9f19ce68bcb4d672aa11be1bd6bd2ee",
    strip_prefix = "bazel-toolchains-5.1.0",
    urls = ["https://github.com/bazelbuild/bazel-toolchains/archive/v5.1.0.tar.gz"],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()
