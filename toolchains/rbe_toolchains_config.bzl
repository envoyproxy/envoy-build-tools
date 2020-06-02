load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_toolchains//rules:rbe_repo.bzl", "rbe_autoconfig")
load("@envoy_build_tools//toolchains:configs/linux/versions.bzl", _generated_toolchain_config_suite_autogen_spec_linux = "TOOLCHAIN_CONFIG_AUTOGEN_SPEC")
load("@envoy_build_tools//toolchains:configs/windows/versions.bzl", _generated_toolchain_config_suite_autogen_spec_windows = "TOOLCHAIN_CONFIG_AUTOGEN_SPEC")

_ENVOY_BUILD_IMAGE_REGISTRY = "gcr.io"

_ENVOY_BUILD_IMAGE_TAG = "12b3d2c2ffa582507e5d6dd34632b2b990f1b195"

_ENVOY_BUILD_IMAGE_REPOSITORY_LINUX = "envoy-ci/envoy-build"
_ENVOY_BUILD_IMAGE_DIGEST_LINUX = "sha256:249b03b6a1e85c79093aa88400afffa8c34ccafc850d690292d36941041b4b7d"
_CONFIGS_OUTPUT_BASE_LINUX = "toolchains/configs/linux"

_ENVOY_BUILD_IMAGE_REPOSITORY_WINDOWS = "envoy-ci/envoy-build-windows"
_ENVOY_BUILD_IMAGE_DIGEST_WINDOWS = "sha256:8acd35d210896ad31afd3f8af75fcfc970a80d360dfeb30f7f0495c67ba74c67"
_CONFIGS_OUTPUT_BASE_WINDOWS = "toolchains/configs/windows"

_CLANG_ENV = {
    "BAZEL_COMPILER": "clang",
    "BAZEL_LINKLIBS": "-l%:libstdc++.a",
    "BAZEL_LINKOPTS": "-lm:-fuse-ld=lld",
    "BAZEL_USE_LLVM_NATIVE_COVERAGE": "1",
    "GCOV": "llvm-profdata",
    "CC": "clang",
    "CXX": "clang++",
    "PATH": "/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/llvm/bin",
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
    "PATH": "/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/llvm/bin",
}

_MSVC_CL_ENV = {}

_TOOLCHAIN_CONFIG_SUITE_SPEC_LINUX = {
    "container_registry": _ENVOY_BUILD_IMAGE_REGISTRY,
    "container_repo": _ENVOY_BUILD_IMAGE_REPOSITORY_LINUX,
    "output_base": _CONFIGS_OUTPUT_BASE_LINUX,
    "repo_name": "envoy_build_tools",
    "toolchain_config_suite_autogen_spec": _generated_toolchain_config_suite_autogen_spec_linux,
}

_TOOLCHAIN_CONFIG_SUITE_SPEC_WINDOWS = {
    "container_registry": _ENVOY_BUILD_IMAGE_REGISTRY,
    "container_repo": _ENVOY_BUILD_IMAGE_REPOSITORY_WINDOWS,
    "output_base": _CONFIGS_OUTPUT_BASE_WINDOWS,
    "repo_name": "envoy_build_tools",
    "toolchain_config_suite_autogen_spec": _generated_toolchain_config_suite_autogen_spec_windows,
}

def _envoy_rbe_toolchain(name, env, toolchain_config_spec_name, toolchain_config_suite_spec, container_image_digest, generator, force):
    if generator:
        rbe_autoconfig(
            name = name + "_gen",
            create_java_configs = False,
            digest = container_image_digest,
            env = env,
            export_configs = True,
            registry = toolchain_config_suite_spec["container_registry"],
            repository = toolchain_config_suite_spec["container_repo"],
            toolchain_config_spec_name = toolchain_config_spec_name,
            toolchain_config_suite_spec = toolchain_config_suite_spec,
            use_checked_in_confs = "False",
        )

    rbe_autoconfig(
        name = name,
        create_java_configs = False,
        digest = container_image_digest,
        env = env,
        registry = toolchain_config_suite_spec["container_registry"],
        repository = toolchain_config_suite_spec["container_repo"],
        toolchain_config_spec_name = toolchain_config_spec_name,
        toolchain_config_suite_spec = toolchain_config_suite_spec,
        use_checked_in_confs = "Force" if force else "Try",
    )

def rbe_toolchains_config(generator = False, force = False):
    _envoy_rbe_toolchain("rbe_ubuntu_clang", _CLANG_ENV, "clang", _TOOLCHAIN_CONFIG_SUITE_SPEC_LINUX, _ENVOY_BUILD_IMAGE_DIGEST_LINUX, generator, force)
    _envoy_rbe_toolchain("rbe_ubuntu_clang_libcxx", _CLANG_LIBCXX_ENV, "clang_libcxx", _TOOLCHAIN_CONFIG_SUITE_SPEC_LINUX, _ENVOY_BUILD_IMAGE_DIGEST_LINUX, generator, force)
    _envoy_rbe_toolchain("rbe_ubuntu_gcc", _GCC_ENV, "gcc", _TOOLCHAIN_CONFIG_SUITE_SPEC_LINUX, _ENVOY_BUILD_IMAGE_DIGEST_LINUX, generator, force)
    _envoy_rbe_toolchain("rbe_windows_msvc_cl", _MSVC_CL_ENV, "msvc-cl", _TOOLCHAIN_CONFIG_SUITE_SPEC_WINDOWS, _ENVOY_BUILD_IMAGE_DIGEST_WINDOWS, generator, force)
