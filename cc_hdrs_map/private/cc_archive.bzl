""" This module contains definition of cc_archive rule. """

load("@rules_cc_hdrs_map//cc_hdrs_map/actions:defs.bzl", "actions")
load("@rules_cc_hdrs_map//cc_hdrs_map/private:attrs.bzl", "get_cc_archive_attrs")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl", "HdrsMapInfo")

CC_ARCHIVE_ATTRS = get_cc_archive_attrs()

def _cc_archive_impl(ctx):
    compilation_ctx, compilation_outputs, hdrs_map_ctx = actions.compile(**actions.compile_kwargs(ctx, CC_ARCHIVE_ATTRS))

    linking_results = actions.link_to_archive(
        compilation_outputs,
        **actions.link_to_archive_kwargs(ctx, CC_ARCHIVE_ATTRS)
    )

    return [
        DefaultInfo(
            files = depset(
                linking_results.cc_linking_outputs.static_libraries,
            ),
        ),
        CcInfo(
            compilation_context = compilation_ctx,
            linking_context = linking_results.linking_context,
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

cc_archive = rule(
    implementation = _cc_archive_impl,
    attrs = {k: v.attr for k, v in CC_ARCHIVE_ATTRS.items()} | {
        "_use_auto_exec_groups": attr.bool(default = True),
    },
    doc = """Produce an archive file.

    The intended major difference between this rule and rules_cc's `cc_static_library`,
    is that this rule does not intend to pull-in all static dependencies.
    """,
    fragments = ["cpp"],
    provides = [DefaultInfo, CcInfo, HdrsMapInfo],
    subrules = [actions.compile, actions.link_to_archive],
)
