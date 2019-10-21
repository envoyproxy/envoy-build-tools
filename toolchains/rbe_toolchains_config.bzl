load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_toolchains//rules:rbe_repo.bzl", "rbe_autoconfig")
load("@envoy_build_tools//toolchains:configs/versions.bzl", _generated_toolchain_config_suite_autogen_spec = "TOOLCHAIN_CONFIG_AUTOGEN_SPEC")

_ENVOY_BUILD_IMAGE_REGISTRY = "gcr.io"
_ENVOY_BUILD_IMAGE_REPOSITORY = "envoy-ci/envoy-build"
_ENVOY_BUILD_IMAGE_DIGEST = "sha256:3ca8acc35fdb57ab26e1bb5f9488f37095f45acd77a12602510410dbefa00b58"
_CONFIGS_OUTPUT_BASE = "toolchains/configs"

_CLANG_ENV = {
    "BAZEL_COMPILER": "clang",
    "BAZEL_LINKLIBS": "-l%:libstdc++.a",
    "BAZEL_LINKOPTS": "-lm:-fuse-ld=lld",
    "BAZEL_USE_LLVM_NATIVE_COVERAGE": "1",
    "GCOV": "llvm-profdata",
    "CC": "clang",
    "CXX": "clang++",
    "PATH": "/usr/sbin:/usr/bin:/sbin:/bin:/opt/llvm/bin",
}

_CLANG_LIBCXX_ENV = dicts.add(_CLANG_ENV, {
    "BAZEL_LINKLIBS": "-l%:libc++.a:-l%:libc++abi.a",
    "BAZEL_LINKOPTS": "-lm:-pthread:-fuse-ld=lld",
    "BAZEL_CXXOPTS": "-stdlib=libc++",
    "CXXFLAGS": "-stdlib=libc++",
})

_GCC_ENV = {
    "BAZEL_COMPILER": "gcc",
    "BAZEL_LINKLIBS": "-l%:libstdc++.a",
    "BAZEL_LINKOPTS": "-lm",
    "CC": "gcc",
    "CXX": "g++",
    "PATH": "/usr/sbin:/usr/bin:/sbin:/bin:/opt/llvm/bin",
}

_TOOLCHAIN_CONFIG_SUITE_SPEC = {
    "container_registry": _ENVOY_BUILD_IMAGE_REGISTRY,
    "container_repo": _ENVOY_BUILD_IMAGE_REPOSITORY,
    "output_base": _CONFIGS_OUTPUT_BASE,
    "repo_name": "envoy_build_tools",
    "toolchain_config_suite_autogen_spec": _generated_toolchain_config_suite_autogen_spec,
}

def _envoy_rbe_toolchain(name, env, toolchain_config_spec_name, generator):
    if generator:
        rbe_autoconfig(
            name = name + "_gen",
            export_configs = True,
            create_java_configs = False,
            digest = _ENVOY_BUILD_IMAGE_DIGEST,
            registry = _ENVOY_BUILD_IMAGE_REGISTRY,
            repository = _ENVOY_BUILD_IMAGE_REPOSITORY,
            env = env,
            toolchain_config_spec_name = toolchain_config_spec_name,
            toolchain_config_suite_spec = _TOOLCHAIN_CONFIG_SUITE_SPEC,
            use_checked_in_confs = "False",
        )

    rbe_autoconfig(
        name = name,
        create_java_configs = False,
        digest = _ENVOY_BUILD_IMAGE_DIGEST,
        registry = _ENVOY_BUILD_IMAGE_REGISTRY,
        repository = _ENVOY_BUILD_IMAGE_REPOSITORY,
        toolchain_config_spec_name = toolchain_config_spec_name,
        toolchain_config_suite_spec = _TOOLCHAIN_CONFIG_SUITE_SPEC,
        use_checked_in_confs = "Force",
    )

def rbe_toolchains_config(generator = False):
    _envoy_rbe_toolchain("rbe_ubuntu_clang", _CLANG_ENV, "clang", generator)
    _envoy_rbe_toolchain("rbe_ubuntu_clang_libcxx", _CLANG_LIBCXX_ENV, "clang_libcxx", generator)
    _envoy_rbe_toolchain("rbe_ubuntu_gcc", _GCC_ENV, "gcc", generator)
