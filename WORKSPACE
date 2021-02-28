workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "1adf7a8e9901287c644dcf9ca08dd8d67a69df94bedbd57a841490a84dc1e9ed",
    strip_prefix = "bazel-toolchains-5.0.0",
    urls = ["https://github.com/bazelbuild/bazel-toolchains/archive/v5.0.0.tar.gz"],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()

#load("//toolchains:rbe_toolchains_config.bzl", "rbe_toolchains_config")

#rbe_toolchains_config(generator = True)
