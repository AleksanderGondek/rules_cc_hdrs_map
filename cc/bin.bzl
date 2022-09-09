""" To be described. """

load(
    "@bazel_tools//tools/cpp:toolchain_utils.bzl",
    "find_cpp_toolchain",
    "use_cpp_toolchain",
)
load(
    "@rules_cc_hdrs_map//cc:common.bzl",
    "get_feature_configuration",
    "prepare_for_compilation",
    "compile",
    "link_to_binary",
)
load(
    "@rules_cc_hdrs_map//cc:conf.bzl",
    "COMMON_RULES_ATTRS",
)

def _cc_bin_with_hdrs_map_impl(ctx):
    """ To be described. """

    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = get_feature_configuration(ctx, cc_toolchain)

    compilation_prep_ctx = prepare_for_compilation(
        actions = ctx.actions,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        input_hdrs_map = ctx.attr.hdrs_map,
        input_public_hdrs = ctx.files.public_hdrs,
        input_private_hdrs = ctx.files.private_hdrs,
        input_deps = ctx.attr.deps,
        input_includes = ctx.attr.includes
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
        user_compile_flags = ctx.attr.copts if ctx.attr.copts else [],
        defines = ctx.attr.defines if ctx.attr.defines else [],
        includes = includes,
        local_defines = ctx.attr.local_defines if ctx.attr.local_defines else [],
    )

    linking_output = link_to_binary(
        name = ctx.label.name,
        actions = ctx.actions,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        compilation_outputs = compilation_outputs,
        deps = deps,
        user_link_flags = ctx.attr.linkopts if ctx.attr.linkopts else [],
        link_deps_statically = ctx.attr.linkstatic,
        stamp = ctx.attr.stamp,
        additional_inputs = ctx.attr.additional_linker_inputs if ctx.attr.additional_linker_inputs else [],
    )

    output_files = []
    if linking_output.executable:
        output_files.append(linking_output.executable)
    elif linking_output.library_to_link:
        fail("'cc_bin_with_hdrs_map' must not output a library!")

    return [
        DefaultInfo(
            executable = linking_output.executable,
            files = depset(output_files),
        ),
    ]

cc_bin_with_hdrs_map = rule(
    implementation = _cc_bin_with_hdrs_map_impl,
    attrs = { 
        **COMMON_RULES_ATTRS, 
        **{
            "additional_linker_inputs": attr.label_list(
                doc = "",
            ),
            "copts": attr.string_list(
                doc = "",
            ),
            "defines": attr.string_list(
                doc = "",
            ),
            "includes": attr.string_list(
                doc = "",
            ),
            "linkopts": attr.string_list(
                doc = "",
            ),
            "linkstatic": attr.bool(
                default = True,
                doc = "",
            ),
            "local_defines": attr.string_list(
                doc = "",
            ),
            "stamp": attr.int(
                default = -1,
                doc = "",
            ),
            "_cc_toolchain": attr.label(
                default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
            ),
        },
    },
    toolchains = use_cpp_toolchain(),
    fragments = ["cpp"],
    executable = True,
    provides = [
        DefaultInfo,
    ],
)
