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
    "create_shared_library",
    "link"
)

def _cc_bin_with_header_maps_impl(ctx):
    """ To be described. """

    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = get_feature_configuration(ctx, cc_toolchain)

    compilation_ctx, compilation_outputs = compile(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        srcs = ctx.files.srcs,
    )

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    # TODO: Is this needed?
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

    linking_output = link(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        compilation_outputs = compilation_outputs,
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
