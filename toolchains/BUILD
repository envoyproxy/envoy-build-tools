licenses(["notice"])  # Apache 2

load("@bazel_toolchains//rules/exec_properties:exec_properties.bzl", "create_rbe_exec_properties_dict")

# Platforms for bazel 3.7.2
platform(
    name = "rbe_linux_clang_platform_3_7_2",
    exec_properties = create_rbe_exec_properties_dict(
        docker_add_capabilities = "SYS_PTRACE,NET_RAW,NET_ADMIN",
        docker_network = "standard",
    ),
    parents = ["//toolchains/configs/linux/clang/bazel_3.7.2/config:platform"],
)

platform(
    name = "rbe_linux_clang_libcxx_platform_3_7_2",
    exec_properties = create_rbe_exec_properties_dict(
        docker_add_capabilities = "SYS_PTRACE,NET_RAW,NET_ADMIN",
        docker_network = "standard",
    ),
    parents = ["//toolchains/configs/linux/clang_libcxx/bazel_3.7.2/config:platform"],
)

platform(
    name = "rbe_linux_gcc_platform_3_7_2",
    exec_properties = create_rbe_exec_properties_dict(
        docker_add_capabilities = "SYS_PTRACE,NET_RAW,NET_ADMIN",
        docker_network = "standard",
    ),
    parents = ["//toolchains/configs/linux/gcc/bazel_3.7.2/config:platform"],
)

platform(
    name = "rbe_windows_clang_cl_platform_3_7_2",
    parents = ["//toolchains/configs/windows/clang-cl/bazel_3.7.2/config:platform"],
)

platform(
    name = "rbe_windows_msvc_cl_platform_3_7_2",
    parents = ["//toolchains/configs/windows/msvc-cl/bazel_3.7.2/config:platform"],
)

# Platforms for bazel 4.1.0
platform(
    name = "rbe_linux_clang_platform_4_1_0",
    exec_properties = create_rbe_exec_properties_dict(
        docker_add_capabilities = "SYS_PTRACE,NET_RAW,NET_ADMIN",
        docker_network = "standard",
    ),
    parents = ["//toolchains/configs/linux/clang/bazel_4.1.0/config:platform"],
)

platform(
    name = "rbe_linux_clang_libcxx_platform_4_1_0",
    exec_properties = create_rbe_exec_properties_dict(
        docker_add_capabilities = "SYS_PTRACE,NET_RAW,NET_ADMIN",
        docker_network = "standard",
    ),
    parents = ["//toolchains/configs/linux/clang_libcxx/bazel_4.1.0/config:platform"],
)

platform(
    name = "rbe_linux_gcc_platform_4_1_0",
    exec_properties = create_rbe_exec_properties_dict(
        docker_add_capabilities = "SYS_PTRACE,NET_RAW,NET_ADMIN",
        docker_network = "standard",
    ),
    parents = ["//toolchains/configs/linux/gcc/bazel_4.1.0/config:platform"],
)

platform(
    name = "rbe_windows_clang_cl_platform_4_1_0",
    parents = ["//toolchains/configs/windows/clang-cl/bazel_4.1.0/config:platform"],
)

platform(
    name = "rbe_windows_msvc_cl_platform_4_1_0",
    parents = ["//toolchains/configs/windows/msvc-cl/bazel_4.1.0/config:platform"],
)
