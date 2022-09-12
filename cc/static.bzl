""" To be described. """

load(
    "@bazel_tools//tools/cpp:toolchain_utils.bzl",
    "find_cpp_toolchain",
    "use_cpp_toolchain",
)
load(
    "@rules_cc_hdrs_map//cc:common.bzl",
    "get_feature_configuration",
    "prepare_for_compilation",
    "compile",
    "link_to_archive",
)
load(
    "@rules_cc_hdrs_map//cc:conf.bzl",
    "CC_STATIC_ATTRS",
)
load(
    "@rules_cc_hdrs_map//cc:hdrs_map.bzl",
    "HdrsMapInfo",
)

def _cc_static(ctx):
    """ To be described. """

    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = get_feature_configuration(ctx, cc_toolchain)

    compilation_prep_ctx = prepare_for_compilation(
        actions = ctx.actions,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        input_hdrs_map = ctx.attr.hdrs_map,
        input_public_hdrs = ctx.files.public_hdrs,
        input_private_hdrs = ctx.files.private_hdrs,
        input_deps = ctx.attr.deps,
        input_includes = ctx.attr.includes
    )

    hdrs_map = compilation_prep_ctx.hdrs_map
    public_hdrs = compilation_prep_ctx.public_hdrs
    private_hdrs = compilation_prep_ctx.private_hdrs
    includes = compilation_prep_ctx.includes
    deps = compilation_prep_ctx.deps

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

    linking_result = link_to_archive(
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
    attrs = CC_STATIC_ATTRS,
    toolchains = use_cpp_toolchain(),
    fragments = ["cpp"],
    provides = [
        DefaultInfo,
        CcInfo,
        HdrsMapInfo,
    ],
)
