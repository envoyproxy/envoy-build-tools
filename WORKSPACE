workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "5d48b13686081f5d07dbba1271595d1bb2b5fa1d2f8c049ef15011bd4e6bdd19",
    strip_prefix = "bazel-toolchains-834b89b3f608a9aa4c212e7ee4a05b323b980a85",
    # 2020-05-21
    urls = ["https://github.com/bazelbuild/bazel-toolchains/archive/834b89b3f608a9aa4c212e7ee4a05b323b980a85.tar.gz"],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()

load("//toolchains:rbe_toolchains_config.bzl", "rbe_toolchains_config")

rbe_toolchains_config(generator = True)
