""" Module providing means of enriching header file groups with mapping metadata. """

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
    doc = """
This rule allows for grouping header files as a unit and 
equipping them with a headers map. Thanks to this approach, 
information about expected include paths may be kept close
to the header files themselve, instead of being repeated 
in multiple compilation targets. 

Example:
```python
cc_hdrs(
    name = "foo_hdrs",
    hdrs_map = {
        "**/*.hpp": ["bar/{filename}"],
    },
    public_hdrs = [
        "foo.hpp",
    ],
)
```
""",
)
