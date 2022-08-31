""" To be described. """

load(
    "@bazel_tools//tools/cpp:toolchain_utils.bzl",
    "find_cpp_toolchain",
    "use_cpp_toolchain"
)

def _cc_bin_with_header_maps_impl(ctx):
    """ To be described. """

    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    # compilation_contexts = [dep[CcInfo].compilation_context for dep in deps]
    compilation_ctx, compilation_outputs = cc_common.compile(
        name = ctx.label.name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        srcs = ctx.files.srcs,
        # includes = includes,
        # defines = defines,
        # public_hdrs = hdrs,
        # compilation_contexts = compilation_contexts,
        # ...
    )

    # TODO: Is this needed?
    # linking_contexts = [dep[CcInfo].linking_context for dep in deps]
    linking_context, linking_output = cc_common.create_linking_context_from_compilation_outputs(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        compilation_outputs = compilation_outputs,
        # linking_contexts = linking_contexts,
        name = ctx.label.name,
    )

    # Stopping here yields a nice .so library
    # output_files = []
    # if linking_output.library_to_link.static_library:
    #     output_files.append(linking_output.library_to_link.static_library)
    # if linking_output.library_to_link.dynamic_library:
    #     output_files.append(linking_output.library_to_link.dynamic_library)

    linking_output = cc_common.link(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        compilation_outputs = compilation_outputs,
        name = ctx.label.name,
        output_type = "executable",
    )

    output_files = []
    if linking_output.executable:
        output_files.append(linking_output.executable)
    if linking_output.library_to_link:
        if linking_output.library_to_link.static_library:
            output_files.append(linking_output.library_to_link.static_library)
        if linking_output.library_to_link.dynamic_library:
            output_files.append(linking_output.library_to_link.dynamic_library)

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
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = [".cpp"],
        ),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
    },
    toolchains = use_cpp_toolchain(),
    fragments = ["cpp"],
    executable = True,
)
