load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _non_module_deps_impl(ctx):
    http_archive(
        name = "bazel_toolchains",
        sha256 = "02e4f3744f1ce3f6e711e261fd322916ddd18cccd38026352f7a4c0351dbda19",
        strip_prefix = "bazel-toolchains-5.1.2",
        urls = ["https://github.com/bazelbuild/bazel-toolchains/archive/refs/tags/v5.1.2.tar.gz"],
    )


non_module_deps = module_extension(implementation = _non_module_deps_impl)