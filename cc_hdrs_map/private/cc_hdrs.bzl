""" This module contains implementation of cc_hdrs rule. """

load("@rules_cc_hdrs_map//cc_hdrs_map/actions:defs.bzl", "actions")
load("@rules_cc_hdrs_map//cc_hdrs_map/private:attrs.bzl", "get_cc_hdrs_attrs")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl", "HdrsMapInfo", "merge_hdrs_maps_info_from_deps")

CC_HDRS_ATTRS = get_cc_hdrs_attrs()

def _cc_hdrs_impl(ctx):
    public_hdrs = [h for h in ctx.files.public_hdrs]
    private_hdrs = [h for h in ctx.files.private_hdrs]
    deps = [d for d in ctx.attr.deps]

    deps_pub_hdrs, deps_prv_hdrs, hdrs_map, deps_deps = merge_hdrs_maps_info_from_deps(
        deps,
        ctx.attr.hdrs_map if ctx.attr.hdrs_map else {},
    )

    public_hdrs.extend(deps_pub_hdrs)
    private_hdrs.extend(deps_prv_hdrs)
    deps.extend(deps_deps)

    return [
        DefaultInfo(
            files = depset(
                [],
                transitive = [
                    depset(public_hdrs),
                    depset(private_hdrs),
                ],
            ),
        ),
        HdrsMapInfo(
            public_hdrs = depset(public_hdrs),
            private_hdrs = depset(private_hdrs),
            hdrs_map = hdrs_map,
            deps = depset([
                d
                for d in deps
            ]),
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
