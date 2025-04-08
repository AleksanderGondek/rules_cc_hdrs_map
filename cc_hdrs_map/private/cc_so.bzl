""" This module contains the implementation of the cc_so rule. """

load("@rules_cc_hdrs_map//cc_hdrs_map/actions:defs.bzl", "actions")
load("@rules_cc_hdrs_map//cc_hdrs_map/private:attrs.bzl", "get_cc_so_attrs")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl", "HdrsMapInfo")

CC_SO_ATTRS = get_cc_so_attrs()

def _cc_so_impl(ctx):
    compilation_ctx, compilation_outputs, hdrs_map_ctx = actions.compile(**actions.compile_kwargs(ctx, CC_SO_ATTRS))

    linking_context, linking_outputs = actions.link_to_so(
        compilation_outputs,
        **actions.link_to_so_kwargs(ctx, CC_SO_ATTRS)
    )

    output_files = []
    if linking_outputs.library_to_link.static_library:
        output_files.append(linking_outputs.library_to_link.static_library)
    if linking_outputs.library_to_link.dynamic_library:
        output_files.append(linking_outputs.library_to_link.dynamic_library)

    return [
        DefaultInfo(
            files = depset(output_files),
        ),
        CcInfo(
            compilation_context = compilation_ctx,
            linking_context = linking_context,
        ),
        HdrsMapInfo(
            public_hdrs = depset(hdrs_map_ctx.public_hdrs),
            private_hdrs = depset(hdrs_map_ctx.private_hdrs),
            hdrs_map = hdrs_map_ctx.hdrs_map,
            deps = depset([
                d
                for d in hdrs_map_ctx.deps
            ]),
        ),
    ]

cc_so = rule(
    implementation = _cc_so_impl,
    attrs = {k: v.attr for k, v in CC_SO_ATTRS.items()} | {
        "_use_auto_exec_groups": attr.bool(default = True),
    },
    doc = """Produce shared object library.

    The intended difference between this rule and the rules_cc's cc_shared_library is
    to unify handling of dependencies that are equipped with CcInfo and CcSharedLibraryInfo
    (use singular attribute of deps to track them both).
    """,
    fragments = ["cpp"],
    provides = [DefaultInfo, CcInfo, HdrsMapInfo],
    subrules = [actions.compile, actions.link_to_so],
)
