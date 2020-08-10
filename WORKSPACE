workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "e2589210b2af5299c6b46e7017315d6a1bd1e91d1f0c419f4efd29e89c6106c7",
    strip_prefix = "bazel-toolchains-c2c03dc21182b10f703bda7fdb5d01617fa0e741",
    urls = ["https://github.com/greenhouse-org/bazel-toolchains/archive/c2c03dc21182b10f703bda7fdb5d01617fa0e741.tar.gz"],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()

load("//toolchains:rbe_toolchains_config.bzl", "rbe_toolchains_config")

rbe_toolchains_config(generator = True)
