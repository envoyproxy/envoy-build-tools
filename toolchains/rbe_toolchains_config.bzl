load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_toolchains//rules:rbe_repo.bzl", "rbe_autoconfig")
load("@bazel_toolchains//rules/exec_properties:exec_properties.bzl", "create_rbe_exec_properties_dict")
load("@envoy_build_tools//toolchains:configs/linux/versions.bzl", _generated_toolchain_config_suite_autogen_spec_linux = "TOOLCHAIN_CONFIG_AUTOGEN_SPEC")
load("@envoy_build_tools//toolchains:configs/windows/versions.bzl", _generated_toolchain_config_suite_autogen_spec_windows = "TOOLCHAIN_CONFIG_AUTOGEN_SPEC")

_ENVOY_BUILD_IMAGE_REGISTRY = "gcr.io"
_ENVOY_BUILD_IMAGE_TAG = "27657977b4773c0e30b65e2030cf242d88d45bd3"

_ENVOY_BUILD_IMAGE_REPOSITORY_LINUX = "envoy-ci/envoy-build"
_ENVOY_BUILD_IMAGE_DIGEST_LINUX = "sha256:0882ab78dc5cae3878061be84dfb6bc73d2e71f5566a8e90b8061c8436c2a958"
_CONFIGS_OUTPUT_BASE_LINUX = "toolchains/configs/linux"

_ENVOY_BUILD_IMAGE_REPOSITORY_WINDOWS = "envoy-ci/envoy-build-windows"
_ENVOY_BUILD_IMAGE_DIGEST_WINDOWS = "sha256:e26d708b0814797d0a0a543f356a0b23bc0b4769da49c789443be182d9f57650"
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

_CLANG_CL_ENV = {
    "USE_CLANG_CL": "1",
}

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

def _envoy_rbe_toolchain(name, env, toolchain_config_spec_name, toolchain_config_suite_spec, container_image_digest, exec_properties, generator, force):
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
            use_legacy_platform_definition = False,
            exec_properties = exec_properties,
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
        use_legacy_platform_definition = False,
        exec_properties = exec_properties,
        use_checked_in_confs = "Force" if force else "Try",
    )

def rbe_toolchains_config(generator = False, force = False):
    linux_exec_properties = create_rbe_exec_properties_dict(docker_add_capabilities = "SYS_PTRACE,NET_RAW,NET_ADMIN", docker_network = "standard")

    _envoy_rbe_toolchain("rbe_ubuntu_clang", _CLANG_ENV, "clang", _TOOLCHAIN_CONFIG_SUITE_SPEC_LINUX, _ENVOY_BUILD_IMAGE_DIGEST_LINUX, linux_exec_properties, generator, force)
    _envoy_rbe_toolchain("rbe_ubuntu_clang_libcxx", _CLANG_LIBCXX_ENV, "clang_libcxx", _TOOLCHAIN_CONFIG_SUITE_SPEC_LINUX, _ENVOY_BUILD_IMAGE_DIGEST_LINUX, linux_exec_properties, generator, force)
    _envoy_rbe_toolchain("rbe_ubuntu_gcc", _GCC_ENV, "gcc", _TOOLCHAIN_CONFIG_SUITE_SPEC_LINUX, _ENVOY_BUILD_IMAGE_DIGEST_LINUX, linux_exec_properties, generator, force)
    _envoy_rbe_toolchain("rbe_windows_msvc_cl", _MSVC_CL_ENV, "msvc-cl", _TOOLCHAIN_CONFIG_SUITE_SPEC_WINDOWS, _ENVOY_BUILD_IMAGE_DIGEST_WINDOWS, {}, generator, force)
    _envoy_rbe_toolchain("rbe_windows_clang_cl", _CLANG_CL_ENV, "clang-cl", _TOOLCHAIN_CONFIG_SUITE_SPEC_WINDOWS, _ENVOY_BUILD_IMAGE_DIGEST_WINDOWS, {}, generator, force)
