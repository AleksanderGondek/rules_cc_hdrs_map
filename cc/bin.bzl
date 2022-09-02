""" To be described. """

load(
    "@bazel_tools//tools/cpp:toolchain_utils.bzl",
    "find_cpp_toolchain",
    "use_cpp_toolchain"
)
load(
    "@rules_cc_header_maps//cc:common.bzl",
    "get_feature_configuration",
    "compile",
    "link"
)
load(
    "@rules_cc_header_maps//cc:header_maps.bzl",
    "materialize_hdrs_mapping",
)

def _cc_bin_with_header_maps_impl(ctx):
    """ To be described. """

    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = get_feature_configuration(ctx, cc_toolchain)

    # Materialize mappings
    public_hdrs_extra_include_path, public_hdrs_extra_files = materialize_hdrs_mapping(
        ctx.actions,
        ctx.attr.header_maps,
        ctx.files.public_hdrs
    )
    public_hdrs = ctx.files.public_hdrs if ctx.files.public_hdrs else []
    if public_hdrs_extra_files:
        public_hdrs = public_hdrs + public_hdrs_extra_files

    private_hdrs_extra_include_path, private_hdrs_extra_files = materialize_hdrs_mapping(
        ctx.actions,
        ctx.attr.header_maps,
        ctx.files.private_hdrs
    )
    private_hdrs = ctx.files.private_hdrs if ctx.files.private_hdrs else []
    if private_hdrs_extra_files:
        private_hdrs = private_hdrs + private_hdrs_extra_files

    includes = ctx.attr.includes if ctx.attr.includes else []
    if public_hdrs_extra_include_path:
        includes.append(public_hdrs_extra_include_path)
    if private_hdrs_extra_include_path:
        includes.append(private_hdrs_extra_include_path)

    compilation_ctx, compilation_outputs = compile(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        srcs = ctx.files.srcs,
        public_hdrs = public_hdrs,
        private_hdrs = private_hdrs,
        deps = ctx.attr.deps if ctx.attr.deps else [],
        user_compile_flags = ctx.attr.copts if ctx.attr.copts else [],
        defines = ctx.attr.defines if ctx.attr.defines else [],
        includes = includes,
        local_defines = ctx.attr.local_defines if ctx.attr.local_defines else [],
    )

    linking_output = link(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        compilation_outputs = compilation_outputs,
        deps = ctx.attr.deps if ctx.attr.deps else [],
        user_link_flags = ctx.attr.linkopts if ctx.attr.linkopts else [],
        link_deps_statically = ctx.attr.linkstatic,
        stamp = ctx.attr.stamp,
        additional_inputs = ctx.attr.additional_linker_inputs if ctx.attr.additional_linker_inputs else [],
    )

    # linking_context, linking_output = create_shared_library(
    #     ctx = ctx,
    #     cc_toolchain = cc_toolchain,
    #     feature_configuration = feature_configuration,
    #     compilation_outputs = compilation_outputs
    # )

    # Stopping here yields a nice .so library
    # output_files = []
    # if linking_output.library_to_link.static_library:
    #     output_files.append(linking_output.library_to_link.static_library)
    # if linking_output.library_to_link.dynamic_library:
    #     output_files.append(linking_output.library_to_link.dynamic_library)

    output_files = []
    if linking_output.executable:
        output_files.append(linking_output.executable)
    elif linking_output.library_to_link:
        fail("'cc_bin_with_header_maps' must not output a library!")

    return [
        DefaultInfo(
          executable = linking_output.executable,
          files = depset(output_files)
        ),
        # CcInfo(
        #     compilation_context = compilation_context,
        #     linking_context = linking_context,
        # ),
    ]

cc_bin_with_header_maps = rule(
    implementation = _cc_bin_with_header_maps_impl,
    attrs = {
        "deps": attr.label_list(
            doc = ""
        ),
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = [
                ".c", ".cc", ".cpp", ".cxx", ".c++", ".C",
            ],
            doc = ""
        ),
        "public_hdrs": attr.label_list(
            allow_files = [
                ".h", ".hh", ".hpp", ".hxx", ".inc", ".inl", ".H"
            ],
            doc = ""
        ),
        "private_hdrs": attr.label_list(
            allow_files = [
                ".h", ".hh", ".hpp", ".hxx", ".inc", ".inl", ".H"
            ],
            doc = ""
        ),
        "header_maps": attr.string_list_dict(
            doc = ""
        ),
        "additional_linker_inputs": attr.label_list(
            doc = ""
        ),
        "copts": attr.string_list(
            doc = ""
        ),
        "defines": attr.string_list(
            doc = ""
        ),
        "includes": attr.string_list(
            doc = ""
        ),
        "linkopts": attr.string_list(
            doc = ""
        ),
        "linkstatic": attr.bool(
            default = True, 
            doc = ""
        ),
        "local_defines": attr.string_list(
            doc = ""
        ),
        "stamp": attr.int(
            default = -1,
            doc = ""
        ),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")
        )
    },
    toolchains = use_cpp_toolchain(),
    fragments = ["cpp"],
    executable = True
)
