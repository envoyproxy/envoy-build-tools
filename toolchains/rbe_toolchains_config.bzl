load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_toolchains//rules:rbe_repo.bzl", "rbe_autoconfig")
load("@envoy_build_tools//toolchains:configs/versions.bzl", _generated_toolchain_config_suite_autogen_spec = "TOOLCHAIN_CONFIG_AUTOGEN_SPEC")

_ENVOY_BUILD_IMAGE_REGISTRY = "gcr.io"
_ENVOY_BUILD_IMAGE_REPOSITORY = "envoy-ci/envoy-build"
_ENVOY_BUILD_IMAGE_DIGEST = "sha256:9236915d10004a35f2439ce4a1c33c1dbb06f95f84c4a4497d4e4f95cdc9e07f"
_CONFIGS_OUTPUT_BASE = "toolchains/configs"

_CLANG_ENV = {
    "BAZEL_COMPILER": "clang",
    "BAZEL_LINKLIBS": "-l%:libstdc++.a",
    "BAZEL_LINKOPTS": "-lm:-static-libgcc:-fuse-ld=lld",
    "BAZEL_USE_LLVM_NATIVE_COVERAGE": "1",
    "GCOV": "llvm-profdata",
    "CC": "clang",
    "CXX": "clang++",
    "PATH": "/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/llvm-9/bin",
}

_CLANG_LIBCXX_ENV = dicts.add(_CLANG_ENV, {
    "BAZEL_LINKLIBS": "-l%:libc++.a:-l%:libc++abi.a",
    "BAZEL_LINKOPTS": "-lm:-static-libgcc:-pthread:-fuse-ld=lld",
    "BAZEL_CXXOPTS": "-stdlib=libc++",
    "CXXFLAGS": "-stdlib=libc++",
})

_GCC_ENV = {
    "BAZEL_COMPILER": "gcc",
    "BAZEL_LINKLIBS": "-l%:libstdc++.a",
    "BAZEL_LINKOPTS": "-lm:-static-libgcc",
    "CC": "gcc",
    "CXX": "g++",
    "PATH": "/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/llvm-9/bin",
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
            # base_container_digest = _ENVOY_BUILD_BASE_IMAGE_DIGEST,
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
        # base_container_digest = _ENVOY_BUILD_BASE_IMAGE_DIGEST,
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
