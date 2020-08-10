workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    patch_args = ["-p1"],
    patches = ["//:toolchain.patch"],
    sha256 = "7ebb200ed3ca3d1f7505659c7dfed01c4b5cb04c3a6f34140726fe22f5d35e86",
    strip_prefix = "bazel-toolchains-3.4.1",
    urls = ["https://github.com/bazelbuild/bazel-toolchains/releases/download/3.4.1/bazel-toolchains-3.4.1.tar.gz"],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()

load("//toolchains:rbe_toolchains_config.bzl", "rbe_toolchains_config")

rbe_toolchains_config(generator = True)
