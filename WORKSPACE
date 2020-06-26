workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "a802b753e127a6f73f3f300db5dd83fb618cd798bc880b6a87db9a8777b7939f",
    strip_prefix = "bazel-toolchains-3.3.0",
    urls = ["https://github.com/bazelbuild/bazel-toolchains/releases/download/3.3.0/bazel-toolchains-3.3.0.tar.gz"],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()

load("//toolchains:rbe_toolchains_config.bzl", "rbe_toolchains_config")

rbe_toolchains_config(generator = True)
