workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "2431088b38fd8e2878db17e3c5babb431de9e5c52b6d8b509d3070fa279a5be2",
    strip_prefix = "bazel-toolchains-3.3.1",
    urls = ["https://github.com/bazelbuild/bazel-toolchains/releases/download/3.3.1/bazel-toolchains-3.3.1.tar.gz"],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()

load("//toolchains:rbe_toolchains_config.bzl", "rbe_toolchains_config")

rbe_toolchains_config(generator = True)
