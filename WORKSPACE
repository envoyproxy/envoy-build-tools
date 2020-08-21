workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "09642745581d071c7cd670e57589ea1ba78c99e9d7edb8b7478bda2640773e90",
    strip_prefix = "bazel-toolchains-022dcbb331a80548cefecc289f3741b98b882307",
    urls = ["https://github.com/bazelbuild/bazel-toolchains/archive/022dcbb331a80548cefecc289f3741b98b882307.tar.gz"],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()

load("//toolchains:rbe_toolchains_config.bzl", "rbe_toolchains_config")

rbe_toolchains_config(generator = True)
