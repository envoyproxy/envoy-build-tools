workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "e2126599d29f2028e6b267eba273dcc8e7f4a35ff323e9600cf42fb03875b7c6",
    strip_prefix = "bazel-toolchains-2.0.0",
    urls = [
        "https://github.com/bazelbuild/bazel-toolchains/releases/download/2.0.0/bazel-toolchains-2.0.0.tar.gz",
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-toolchains/archive/2.0.0.tar.gz",
    ],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()

load("//toolchains:rbe_toolchains_config.bzl", "rbe_toolchains_config")

rbe_toolchains_config(generator = True)
