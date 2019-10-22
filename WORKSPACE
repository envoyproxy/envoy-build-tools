workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "1e16833a9f0e32b292568c0dfee7bd48133c2038605757d3a430551394310006",
    strip_prefix = "bazel-toolchains-1.1.0",
    urls = [
        "https://github.com/bazelbuild/bazel-toolchains/releases/download/1.1.0/bazel-toolchains-1.1.0.tar.gz",
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-toolchains/archive/1.1.0.tar.gz",
    ],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()

load("//toolchains:rbe_toolchains_config.bzl", "rbe_toolchains_config")

rbe_toolchains_config(generator = True)
