""" This module contains implementation of cc_hdrs rule. """

load("@rules_cc_hdrs_map//cc_hdrs_map/actions:defs.bzl", "actions")
load("@rules_cc_hdrs_map//cc_hdrs_map/private:attrs.bzl", "get_cc_hdrs_attrs")
load("@rules_cc_hdrs_map//cc_hdrs_map/private:common.bzl", "prepare_default_runfiles")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl", "new_hdrs_map")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map_info.bzl", "HdrsMapInfo", "quotient_map_hdrs_map_infos")

CC_HDRS_ATTRS = get_cc_hdrs_attrs()

def _cc_hdrs_impl(ctx):
    hdrs = [h for h in ctx.files.hdrs]
    implementation_hdrs = [h for h in ctx.files.implementation_hdrs]
    deps = [d for d in ctx.attr.deps]

    hdrs_map = new_hdrs_map(from_dict = ctx.attr.hdrs_map if ctx.attr.hdrs_map else {})

    # Pattern of '{filename}' resolves to any direct header file of the rule instance
    hdrs_map.pin_down_non_globs(hdrs = hdrs + implementation_hdrs)

    deps_pub_hdrs, deps_prv_hdrs, hdrs_map, deps_deps = quotient_map_hdrs_map_infos(
        targets = deps,
        hdrs = None,
        implementation_hdrs = None,
        hdrs_map = hdrs_map,
        hdrs_map_deps = None,
        # DO NOT pay the transitive traversal cost upfront
        traverse_deps = False,
    )

    hdrs = depset(direct = hdrs, transitive = [deps_pub_hdrs])
    implementation_hdrs = depset(direct = implementation_hdrs, transitive = [deps_prv_hdrs])
    deps = depset(direct = deps, transitive = [deps_deps])

    return [
        DefaultInfo(
            files = depset(
                [],
                transitive = [
                    hdrs,
                    implementation_hdrs,
                ],
            ),
            runfiles = prepare_default_runfiles(ctx.runfiles, ctx.attr.data, ctx.attr.deps, files = ctx.files.data),
        ),
        HdrsMapInfo(
            hdrs = hdrs,
            implementation_hdrs = implementation_hdrs,
            hdrs_map = hdrs_map,
            deps = deps,
        ),
    ]

cc_hdrs = rule(
    implementation = _cc_hdrs_impl,
    attrs = {k: v.attr for k, v in CC_HDRS_ATTRS.items()} | {
        "_use_auto_exec_groups": attr.bool(default = True),
    },
    doc = """Define header files properties.

    This rule groups headers into a singular target and allows
    to attach 'include_path' modifications information to them,
    so that wherever the header files are being used, they can
    be used with their intended include paths.
    """,
    fragments = ["cpp"],
    provides = [DefaultInfo, HdrsMapInfo],
    subrules = [actions.compile, actions.link_to_so],
)
