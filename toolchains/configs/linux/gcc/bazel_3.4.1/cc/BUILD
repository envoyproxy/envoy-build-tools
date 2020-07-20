# Copyright 2016 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This becomes the BUILD file for @local_config_cc// under non-BSD unixes.

package(default_visibility = ["//visibility:public"])

load(":cc_toolchain_config.bzl", "cc_toolchain_config")
load(":armeabi_cc_toolchain_config.bzl", "armeabi_cc_toolchain_config")
load("@rules_cc//cc:defs.bzl", "cc_toolchain", "cc_toolchain_suite")

licenses(["notice"])  # Apache 2.0

cc_library(
    name = "malloc",
)

filegroup(
    name = "empty",
    srcs = [],
)

filegroup(
    name = "cc_wrapper",
    srcs = ["cc_wrapper.sh"],
)

filegroup(
    name = "compiler_deps",
    srcs = glob(["extra_tools/**"], allow_empty = True) + [":builtin_include_directory_paths"],
)

filegroup(
    name = "cross_aarch64_files",
    srcs = glob([
        "aarch64-none-linux-gnu/**",
        "libexec/**",
        "lib/gcc/aarch64-none-linux-gnu/**",
        "include/**",
    ]),
)

# This is the entry point for --crosstool_top.  Toolchains are found
# by lopping off the name of --crosstool_top and searching for
# the "${CPU}" entry in the toolchains attribute.
cc_toolchain_suite(
    name = "toolchain",
    toolchains = {
        "k8|gcc": ":cc-compiler-k8",
        "k8": ":cc-compiler-k8",
        "armeabi-v7a|compiler": ":cc-compiler-armeabi-v7a",
        "armeabi-v7a": ":cc-compiler-armeabi-v7a",
        "aarch64-cross|gcc": ":cc-compiler-aarch64-cross",
        "aarch64-cross": ":cc-compiler-aarch64-cross",
    },
)

cc_toolchain(
    name = "cc-compiler-k8",
    toolchain_identifier = "local",
    toolchain_config = ":local",
    all_files = ":compiler_deps",
    ar_files = ":compiler_deps",
    as_files = ":compiler_deps",
    compiler_files = ":compiler_deps",
    dwp_files = ":empty",
    linker_files = ":compiler_deps",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 1,
    module_map = None,
)

cc_toolchain_config(
    name = "local",
    cpu = "k8",
    compiler = "gcc",
    toolchain_identifier = "local",
    host_system_name = "local",
    target_system_name = "local",
    target_libc = "local",
    abi_version = "local",
    abi_libc_version = "local",
    cxx_builtin_include_directories = ["/usr/lib/gcc/x86_64-linux-gnu/9/include",
    "/usr/local/include",
    "/usr/include/x86_64-linux-gnu",
    "/usr/include",
    "/usr/include/c++/9",
    "/usr/include/x86_64-linux-gnu/c++/9",
    "/usr/include/c++/9/backward"],
    tool_paths = {"ar": "/usr/bin/ar",
        "ld": "/usr/bin/ld",
        "cpp": "/usr/bin/cpp",
        "gcc": "/usr/bin/gcc",
        "dwp": "/usr/bin/dwp",
        "gcov": "None",
        "nm": "/usr/bin/nm",
        "objcopy": "/usr/bin/objcopy",
        "objdump": "/usr/bin/objdump",
        "strip": "/usr/bin/strip"},
    compile_flags = ["-U_FORTIFY_SOURCE",
    "-fstack-protector",
    "-Wall",
    "-Wunused-but-set-parameter",
    "-Wno-free-nonheap-object",
    "-fno-omit-frame-pointer"],
    opt_compile_flags = ["-g0",
    "-O2",
    "-D_FORTIFY_SOURCE=1",
    "-DNDEBUG",
    "-ffunction-sections",
    "-fdata-sections"],
    dbg_compile_flags = ["-g"],
    cxx_flags = ["-std=c++0x"],
    link_flags = ["-fuse-ld=gold",
    "-Wl,-no-as-needed",
    "-Wl,-z,relro,-z,now",
    "-B/usr/bin",
    "-pass-exit-codes",
    "-lm"],
    link_libs = ["-l:libstdc++.a"],
    opt_link_flags = ["-Wl,--gc-sections"],
    unfiltered_compile_flags = ["-fno-canonical-system-headers",
    "-Wno-builtin-macro-redefined",
    "-D__DATE__=\"redacted\"",
    "-D__TIMESTAMP__=\"redacted\"",
    "-D__TIME__=\"redacted\""],
    coverage_compile_flags = ["--coverage"],
    coverage_link_flags = ["--coverage"],
    supports_start_end_lib = True,
)

# Android tooling requires a default toolchain for the armeabi-v7a cpu.
cc_toolchain(
    name = "cc-compiler-armeabi-v7a",
    toolchain_identifier = "stub_armeabi-v7a",
    toolchain_config = ":stub_armeabi-v7a",
    all_files = ":empty",
    ar_files = ":empty",
    as_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 1,
)

armeabi_cc_toolchain_config(name = "stub_armeabi-v7a")

cc_toolchain(
    name = "cc-compiler-aarch64-cross",
    toolchain_identifier = "cross_aarch64",
    toolchain_config = ":cross_aarch64",
    all_files = ":cross_aarch64_files",
    ar_files = ":empty",
    as_files = ":empty",
    compiler_files = ":cross_aarch64_files",
    dwp_files = ":empty",
    linker_files = ":cross_aarch64_files",
    objcopy_files = ":cross_aarch64_files",
    strip_files = ":cross_aarch64_files",
    supports_param_files = 1,
)

cc_toolchain_config(
    name = "cross_aarch64",
    cpu = "aarch64",
    compiler = "gcc",
    toolchain_identifier = "cross_aarch64",
    host_system_name = "local",
    target_system_name = "aarch64-linux-gnu",
    target_libc = "aarch64",
    abi_version = "aarch64",
    abi_libc_version = "aarch64",
    cxx_builtin_include_directories = [
        "/usr/lib/gcc-cross/aarch64-linux-gnu/9/include",
        "/usr/aarch64-linux-gnu/include",
        "/usr/include",
        "/usr/aarch64-linux-gnu/include/c++/9",
        "/usr/aarch64-linux-gnu/include/c++/9/aarch64-linux-gnu",
        "/usr/aarch64-linux-gnu/include/c++/9/backward",
    ],
    tool_paths = {
        "ar": "/usr/bin/aarch64-linux-gnu-ar",
        "compat-ld": "/usr/bin/aarch64-linux-gnu-ld",
        "ld": "/usr/bin/aarch64-linux-gnu-ld",
        "cpp": "/usr/bin/aarch64-linux-gnu-cpp",
        "gcc": "/usr/bin/aarch64-linux-gnu-gcc",
        "dwp": "/usr/bin/aarch64-linux-gnu-dwp",
        "gcov": "/usr/bin/aarch64-linux-gnu-gcov",
        "nm": "/usr/bin/aarch64-linux-gnu-nm",
        "objcopy": "/usr/bin/aarch64-linux-gnu-objcopy",
        "objdump": "/usr/bin/aarch64-linux-gnu-objdump",
        "strip": "/usr/bin/aarch64-linux-gnu-strip",
    },
    compile_flags = [
        "-U_FORTIFY_SOURCE",
        "-fstack-protector",
        "-Wall",
        "-Wunused-but-set-parameter",
        "-Wno-free-nonheap-object",
        "-fno-omit-frame-pointer",
        # GCC uses unsigned char by default for all non-x86
        # architectures which breaks opentracing-cpp and
        # lightstep-tracer-cpp builds, as they are using
        # signed characters. Using signed char by default
        # fixes that.
        "-fsigned-char",
        # Disable assembly code in BoringSSL.
        # TODO(mrostecki): Fix BoringSSL assembly code for
        # aarch64.
        "-DOPENSSL_NO_ASM",
    ],
    opt_compile_flags = [
        "-g0",
        "-O2",
        "-D_FORTIFY_SOURCE=1",
        "-DNDEBUG",
        "-ffunction-sections",
        "-fdata-sections",
    ],
    dbg_compile_flags = ["-g"],
    cxx_flags = ["-std=c++0x"],
    link_flags = [
        "-Wl,-no-as-needed",
        "-Wl,-z,relro,-z,now",
        "-pass-exit-codes",
        "-lm",
    ],
    link_libs = ["-l:libstdc++.a"],
    opt_link_flags = ["-Wl,--gc-sections"],
    unfiltered_compile_flags = [
        "-fno-canonical-system-headers",
        "-Wno-builtin-macro-redefined",
        "-D__DATE__=\"redacted\"",
        "-D__TIMESTAMP__=\"redacted\"",
        "-D__TIME__=\"redacted\"",
    ],
    coverage_compile_flags = ["--coverage"],
    coverage_link_flags = ["--coverage"],
    supports_start_end_lib = False,
)
