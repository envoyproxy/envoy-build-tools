licenses(["notice"])  # Apache 2

load("@bazel_toolchains//rules/exec_properties:exec_properties.bzl", "create_rbe_exec_properties_dict")

platform(
    name = "rbe_linux_clang_platform",
    exec_properties = create_rbe_exec_properties_dict(
        docker_add_capabilities = "SYS_PTRACE,NET_RAW,NET_ADMIN",
        docker_network = "standard",
        docker_privileged = True,
    ),
    parents = ["//toolchains/configs/linux/clang/config:platform"],
)

platform(
    name = "rbe_linux_clang_libcxx_platform",
    exec_properties = create_rbe_exec_properties_dict(
        docker_add_capabilities = "SYS_PTRACE,NET_RAW,NET_ADMIN",
        docker_network = "standard",
        docker_privileged = True,
    ),
    parents = ["//toolchains/configs/linux/clang_libcxx/config:platform"],
)

platform(
    name = "rbe_linux_gcc_platform",
    exec_properties = create_rbe_exec_properties_dict(
        docker_add_capabilities = "SYS_PTRACE,NET_RAW,NET_ADMIN",
        docker_network = "standard",
    ),
    parents = ["//toolchains/configs/linux/gcc/config:platform"],
)
