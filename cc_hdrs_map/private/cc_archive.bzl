""" This module contains definition of cc_archive rule. """

load("@rules_cc_hdrs_map//cc_hdrs_map/actions:defs.bzl", "actions")
load("@rules_cc_hdrs_map//cc_hdrs_map/private:attrs.bzl", "get_cc_archive_attrs")
load("@rules_cc_hdrs_map//cc_hdrs_map/private:common.bzl", "prepare_default_runfiles")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map_info.bzl", "HdrsMapInfo")

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
            runfiles = prepare_default_runfiles(ctx.runfiles, ctx.attr.data, ctx.attr.deps),
        ),
        CcInfo(
            compilation_context = compilation_ctx,
            linking_context = linking_results.linking_context,
        ),
        HdrsMapInfo(
            hdrs = hdrs_map_ctx.hdrs,
            implementation_hdrs = depset([]),
            hdrs_map = hdrs_map_ctx.hdrs_map,
            deps = hdrs_map_ctx.deps,
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
