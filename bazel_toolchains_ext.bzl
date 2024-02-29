load("@bazel_toolchains//repositories:repositories.bzl","repositories")

def _bazel_toolchains_ext_impl(ctx):
    repositories()

bazel_toolchains_ext = module_extension(implementation = _bazel_toolchains_ext_impl)
