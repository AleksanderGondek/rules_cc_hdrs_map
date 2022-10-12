""" Module providing means of compiling executables with usage of mapping metadata. """

load(
    "@bazel_tools//tools/cpp:toolchain_utils.bzl",
    "find_cpp_toolchain",
    "use_cpp_toolchain",
)
load(
    "@rules_cc_hdrs_map//rules:lib/common.bzl",
    "compile",
    "get_feature_configuration",
    "link_to_binary",
    "prepare_for_compilation",
)
load(
    "@rules_cc_hdrs_map//rules:lib/rules_attrs.bzl",
    "get_cc_bin_attrs",
)

def _cc_bin_impl(ctx):
    """ To be described. """

    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = get_feature_configuration(ctx, cc_toolchain)

    compilation_prep_ctx = prepare_for_compilation(
        invoker_label = ctx.label,
        actions = ctx.actions,
        is_windows = ctx.attr._is_windows,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        input_hdrs_map = ctx.attr.hdrs_map,
        input_public_hdrs = ctx.files.public_hdrs,
        input_private_hdrs = ctx.files.private_hdrs,
        input_deps = ctx.attr.deps,
        input_includes = ctx.attr.includes,
    )

    hdrs_map = compilation_prep_ctx.hdrs_map
    public_hdrs = compilation_prep_ctx.public_hdrs
    private_hdrs = compilation_prep_ctx.private_hdrs
    includes = compilation_prep_ctx.includes
    deps = compilation_prep_ctx.deps

    # Compile
    compilation_ctx, compilation_outputs = compile(
        name = ctx.label.name,
        actions = ctx.actions,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        srcs = ctx.files.srcs,
        public_hdrs = public_hdrs,
        private_hdrs = private_hdrs,
        deps = deps,
        # Includes
        include_prefix = "",
        strip_include_prefix = "",
        includes = [],
        quote_includes = includes,
        system_includes = [],
        # Other
        defines = ctx.attr.defines,
        local_defines = ctx.attr.local_defines,
        user_compile_flags = ctx.attr.copts,
    )

    linking_output = link_to_binary(
        name = ctx.label.name,
        actions = ctx.actions,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        compilation_outputs = compilation_outputs,
        deps = deps,
        user_link_flags = ctx.attr.linkopts,
        link_deps_statically = ctx.attr.linkstatic,
        stamp = ctx.attr.stamp,
        additional_inputs = ctx.attr.additional_linker_inputs,
    )

    output_files = []
    if linking_output.executable:
        output_files.append(linking_output.executable)
    elif linking_output.library_to_link:
        fail("'cc_bin' must not output a library!")

    return [
        DefaultInfo(
            executable = linking_output.executable,
            files = depset(output_files),
        ),
    ]

cc_bin = rule(
    implementation = _cc_bin_impl,
    attrs = get_cc_bin_attrs(),
    toolchains = use_cpp_toolchain(),
    fragments = ["cpp"],
    executable = True,
    provides = [
        DefaultInfo,
    ],
    doc = """
This rule allows for compiling code into executables.

Example:
```python
cc_bin(
    name = "foo",
    hdrs_map = {
        "**/*.hpp": ["bar/{filename}"],
    },
    srcs = [
        "foo.cpp",
        "foo.hpp",
    ],
)
```
""",
)
