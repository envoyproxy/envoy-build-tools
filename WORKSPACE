workspace(name = "envoy_build_tools")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_toolchains",
    sha256 = "0f73f35190708dd03066b58bf3a50be2ff9368c654d1cfb8ff4230de10b90dca",
    strip_prefix = "bazel-toolchains-04f865f8e7f412d82051d3a2de422ee31ba0502d",
    urls = ["https://github.com/greenhouse-org/bazel-toolchains/archive/04f865f8e7f412d82051d3a2de422ee31ba0502d.tar.gz"],
)

load(
    "@bazel_toolchains//repositories:repositories.bzl",
    bazel_toolchains_repositories = "repositories",
)

bazel_toolchains_repositories()

load("//toolchains:rbe_toolchains_config.bzl", "rbe_toolchains_config")

rbe_toolchains_config(generator = True)
