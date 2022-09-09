""" To be described. """

load(
    "@bazel_tools//tools/cpp:toolchain_utils.bzl",
    "find_cpp_toolchain",
    "use_cpp_toolchain",
)
load(
    "@rules_cc_hdrs_map//cc:common.bzl",
    "compile",
    "create_static_library",
    "get_feature_configuration",
)
load(
    "@rules_cc_hdrs_map//cc:hdrs_map.bzl",
    "HdrsMapInfo",
    "materialize_hdrs_mapping",
    "merge_hdr_maps_info_from_deps",
)

def _cc_static(ctx):
    """ To be described. """

    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = get_feature_configuration(ctx, cc_toolchain)

    hdrs_map = ctx.attr.hdrs_map if ctx.attr.hdrs_map else {}
    public_hdrs = [h for h in ctx.files.public_hdrs]
    private_hdrs = [h for h in ctx.files.private_hdrs]
    deps = [d for d in ctx.attr.deps]

    # Merge with deps
    deps_pub_hdrs, deps_prv_hdrs, hdrs_map, deps_deps = merge_hdr_maps_info_from_deps(
        deps,
        hdrs_map,
    )
    public_hdrs.extend(deps_pub_hdrs)
    private_hdrs.extend(deps_prv_hdrs)
    deps.extend(deps_deps)

    # Materialize mappings
    public_hdrs_extra_include_path, public_hdrs_extra_files = materialize_hdrs_mapping(
        ctx.actions,
        hdrs_map,
        public_hdrs,
    )
    if public_hdrs_extra_files:
        public_hdrs.extend(public_hdrs_extra_files)

    private_hdrs_extra_include_path, private_hdrs_extra_files = materialize_hdrs_mapping(
        ctx.actions,
        hdrs_map,
        private_hdrs,
    )
    if private_hdrs_extra_files:
        private_hdrs.extend(private_hdrs_extra_files)

    includes = ctx.attr.includes if ctx.attr.includes else []
    if public_hdrs_extra_include_path:
        includes.append(public_hdrs_extra_include_path)
    if private_hdrs_extra_include_path:
        includes.append(private_hdrs_extra_include_path)

    compilation_ctx, compilation_outputs = compile(
        name = ctx.label.name,
        actions = ctx.actions,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        srcs = ctx.files.srcs,
        public_hdrs = public_hdrs,
        private_hdrs = private_hdrs,
        deps = deps,
        user_compile_flags = ctx.attr.copts if ctx.attr.copts else [],
        defines = ctx.attr.defines if ctx.attr.defines else [],
        includes = includes,
        local_defines = ctx.attr.local_defines if ctx.attr.local_defines else [],
    )

    linking_result = create_static_library(
        invoker_label = ctx.label,
        actions = ctx.actions,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        compilation_outputs = compilation_outputs,
        deps = deps,
        user_link_flags = ctx.attr.linkopts if ctx.attr.linkopts else [],
    )

    return [
        DefaultInfo(
            files = depset(
                linking_result.cc_linking_outputs.static_libraries,
            ),
        ),
        CcInfo(
            compilation_context = compilation_ctx,
            linking_context = linking_result.linking_context,
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

cc_static = rule(
    implementation = _cc_static,
    attrs = {
        "deps": attr.label_list(
            doc = "",
        ),
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = [
                ".c",
                ".cc",
                ".cpp",
                ".cxx",
                ".c++",
                ".C",
            ],
            doc = "",
        ),
        "public_hdrs": attr.label_list(
            allow_files = [
                ".h",
                ".hh",
                ".hpp",
                ".hxx",
                ".inc",
                ".inl",
                ".H",
            ],
            doc = "",
        ),
        "private_hdrs": attr.label_list(
            allow_files = [
                ".h",
                ".hh",
                ".hpp",
                ".hxx",
                ".inc",
                ".inl",
                ".H",
            ],
            doc = "",
        ),
        "hdrs_map": attr.string_list_dict(
            doc = "",
        ),
        "copts": attr.string_list(
            doc = "",
        ),
        "defines": attr.string_list(
            doc = "",
        ),
        "includes_prefix": attr.string(
            doc = "",
        ),
        "includes": attr.string_list(
            doc = "",
        ),
        "linkopts": attr.string_list(
            doc = "",
        ),
        "local_defines": attr.string_list(
            doc = "",
        ),
        "strip_include_prefix": attr.string(
            doc = "",
        ),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
    },
    toolchains = use_cpp_toolchain(),
    fragments = ["cpp"],
    provides = [
        DefaultInfo,
        CcInfo,
        HdrsMapInfo,
    ],
)
