""" Module providing means of creating archive files which use mapping metadata. """

load(
    "@bazel_tools//tools/cpp:toolchain_utils.bzl",
    "find_cpp_toolchain",
    "use_cpp_toolchain",
)
load(
    "@rules_cc_hdrs_map//rules:lib/common.bzl",
    "compile",
    "get_feature_configuration",
    "link_to_archive",
    "prepare_for_compilation",
)
load(
    "@rules_cc_hdrs_map//rules:lib/hdrs_map.bzl",
    "HdrsMapInfo",
)
load(
    "@rules_cc_hdrs_map//rules:lib/rules_attrs.bzl",
    "get_cc_archive_attrs",
)

def _cc_archive(ctx):
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = get_feature_configuration(ctx, cc_toolchain)

    compilation_prep_ctx = prepare_for_compilation(
        invoker_label = ctx.label,
        actions = ctx.actions,
        is_windows = ctx.attr._is_windows,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        input_hdrs_map = ctx.attr.hdrs_map,
        input_public_hdrs = ctx.files.public_hdrs,
        input_private_hdrs = ctx.files.private_hdrs,
        input_deps = ctx.attr.deps,
        input_includes = ctx.attr.includes,
    )

    hdrs_map = compilation_prep_ctx.hdrs_map
    public_hdrs = compilation_prep_ctx.public_hdrs
    private_hdrs = compilation_prep_ctx.private_hdrs
    includes = compilation_prep_ctx.includes
    deps = compilation_prep_ctx.deps

    # Compile
    compilation_ctx, compilation_outputs = compile(
        name = ctx.label.name,
        actions = ctx.actions,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        srcs = ctx.files.srcs,
        public_hdrs = public_hdrs,
        private_hdrs = private_hdrs,
        deps = deps,
        # Includes
        include_prefix = ctx.attr.include_prefix,
        strip_include_prefix = ctx.attr.strip_include_prefix,
        includes = [],
        quote_includes = includes,
        system_includes = [],
        # Other
        defines = ctx.attr.defines,
        local_defines = ctx.attr.local_defines,
        user_compile_flags = ctx.attr.copts,
    )

    linking_result = link_to_archive(
        invoker_label = ctx.label,
        actions = ctx.actions,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        compilation_outputs = compilation_outputs,
        deps = deps,
        user_link_flags = ctx.attr.linkopts,
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

cc_archive = rule(
    implementation = _cc_archive,
    attrs = get_cc_archive_attrs(),
    toolchains = use_cpp_toolchain(),
    fragments = ["cpp"],
    provides = [
        DefaultInfo,
        CcInfo,
        HdrsMapInfo,
    ],
    doc = """
This rule allows for creating archive objects,
which can utilize the headers map and propagate them
futher down the dependency chain.

Example:
```python
cc_archive(
    name = "foo",
    hdrs_map = {
        "**/*.hpp": ["bar/{filename}"],
    },
    deps = [
        ":foo_hdrs",
    ],
    srcs = [
        "foo.cpp",
    ],
)
```
""",
)
