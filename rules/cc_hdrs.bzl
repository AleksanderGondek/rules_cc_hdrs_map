""" To be described. """

load(
    "@rules_cc_hdrs_map//rules:lib/hdrs_map.bzl",
    "HdrsMapInfo",
    "merge_hdr_maps_info_from_deps",
)
load(
    "@rules_cc_hdrs_map//rules:lib/rules_attrs.bzl",
    "get_cc_hdrs_attrs",
)

def _cc_hdrs_impl(ctx):
    """ To be described. """
    public_hdrs = [h for h in ctx.files.public_hdrs]
    private_hdrs = [h for h in ctx.files.private_hdrs]
    deps = [d for d in ctx.attr.deps]

    deps_pub_hdrs, deps_prv_hdrs, hdrs_map, deps_deps = merge_hdr_maps_info_from_deps(
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
    attrs = get_cc_hdrs_attrs(),
    fragments = ["cpp"],
    provides = [
        DefaultInfo,
        HdrsMapInfo,
    ],
)
