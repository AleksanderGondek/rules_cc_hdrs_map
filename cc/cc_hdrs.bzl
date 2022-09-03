""" To be described. """

load(
    "@rules_cc_header_maps//cc:header_maps.bzl",
    "HdrMapsInfo",
    "merge_hdr_maps_info_from_deps",
)

def _cc_hdrs_impl(ctx):
    """ To be described. """
    # TODO: Important! non-hdrmapsinfo deps need to be passed-on!
    public_hdrs = [h for h in ctx.files.public_hdrs]
    private_hdrs = [h for h in ctx.files.private_hdrs]

    deps_public_hdrs, deps_private_hdrs, header_maps = merge_hdr_maps_info_from_deps(
        ctx.attr.deps,
        ctx.attr.header_maps if ctx.attr.header_maps else {}
    )

    public_hdrs.extend(deps_public_hdrs)
    private_hdrs.extend(deps_private_hdrs)

    return [
        DefaultInfo(
            files = depset(
              [], 
              transitive = [
                depset(public_hdrs),
                depset(private_hdrs)
              ]
            )
        ),
        HdrMapsInfo(
            public_hdrs = depset(public_hdrs),
            private_hdrs = depset(private_hdrs),
            header_maps = header_maps
    ]


cc_hdrs = rule(
    implementation = _cc_hdrs_impl,
    attrs = {
        # TODO: Is it necessary?
        # "implementation_deps": attr.label_list(
        #     doc = ""
        # ),
        "deps": attr.label_list(
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
        "copts": attr.string_list(
            doc = ""
        ),
        "defines": attr.string_list(
            doc = ""
        ),
        "include_prefix": attr.string(
            doc = ""
        ),
        "includes": attr.string_list(
            doc = ""
        ),
        "linkopts": attr.string_list(
            doc = ""
        ),
        "local_defines": attr.string_list(
            doc = ""
        ),
        "strip_include_prefix": attr.string(
            doc = ""
        ),
        # TODO: Is it necessary?
        # "textual_hdrs": attr.label_list(
        #     doc = ""
        # ),
    },
    fragments = ["cpp"],
    provides = [
        DefaultInfo,
        HdrMapsInfo
    ],
)
