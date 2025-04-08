""" This module contains logic responsible for HdrsMap handling and compilation phase. """

load(
    "@rules_cc//cc:find_cc_toolchain.bzl",
    "find_cc_toolchain",
    "use_cc_toolchain",
)
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl", "HdrsMapInfo", "materialize_hdrs_mapping", "merge_hdrs_maps_info_from_deps")

def prepare_for_compilation(
        sctx,
        input_hdrs_map,
        input_public_hdrs,
        input_private_hdrs,
        input_deps,
        input_includes):
    """Materialize information from hdrs map.

    This function creates a epheremal directory, that contains all of the
    patterns specified within hdrs_map providers, thus making them all
    available under singular, temporary include statment.

    Args:
        sctx: subrule context
        input_hdrs_map: list of HdrsMapInfo which should be used for materialization of compilation context
        input_public_hdrs: direct headers provided to the action
        input_private_hdrs: direct headers provided to the action
        input_deps: dependencies specified for the action
        input_includes: include statements specified for the action
    """
    hdrs_map = input_hdrs_map if input_hdrs_map else {}
    public_hdrs = [h for h in input_public_hdrs]
    private_hdrs = [h for h in input_private_hdrs]
    deps = [d for d in input_deps]

    # Merge with deps
    deps_pub_hdrs, deps_prv_hdrs, hdrs_map, deps_deps = merge_hdrs_maps_info_from_deps(
        deps,
        hdrs_map,
    )
    public_hdrs.extend(deps_pub_hdrs)
    private_hdrs.extend(deps_prv_hdrs)
    deps.extend(deps_deps)

    # Materialize mappings
    public_hdrs_extra_include_path, public_hdrs_extra_files = materialize_hdrs_mapping(
        sctx.label,
        sctx.actions,
        hdrs_map,
        public_hdrs,
    )
    if public_hdrs_extra_files:
        public_hdrs.extend(public_hdrs_extra_files)

    private_hdrs_extra_include_path, private_hdrs_extra_files = materialize_hdrs_mapping(
        sctx.label,
        sctx.actions,
        hdrs_map,
        private_hdrs,
    )
    if private_hdrs_extra_files:
        private_hdrs.extend(private_hdrs_extra_files)

    includes = input_includes if input_includes else []
    if public_hdrs_extra_include_path:
        includes.append(public_hdrs_extra_include_path)
    if private_hdrs_extra_include_path:
        includes.append(private_hdrs_extra_include_path)

    return struct(
        hdrs_map = hdrs_map,
        public_hdrs = public_hdrs,
        private_hdrs = private_hdrs,
        includes = includes,
        deps = deps,
    )

def _compile_impl(
        sctx,
        configure_features_func = None,
        features = [],
        disabled_features = [],
        # Sources
        srcs = [],
        hdrs_map = {},
        public_hdrs = [],
        private_hdrs = [],
        deps = [],
        additional_inputs = [],
        # Includes
        include_prefix = "",
        strip_include_prefix = "",
        includes = [],
        quote_includes = [],
        system_includes = [],
        # Defines
        defines = [],
        local_defines = [],
        # Cflags
        user_compile_flags = [],
        conly_flags = [],
        cxx_flags = [],
        # Other
        disallow_pic_outputs = False,
        disallow_nopic_outputs = False):
    """Perform CC preprocessing, compilation and assmbly steps.

    This subrule runs the preprocessing, compilation and assembly
    by the usage of the Bazel built-in of 'cc_common.compile'.
    In future this might be broken down to custom-defined
    actions but at the moment there is no need to do so.

    Args:
        sctx: subrule context
        configure_features_func: function that will provide [FeatureConfiguration](https://bazel.build/rules/lib/builtins/FeatureConfiguration.html)
        features: list of features specified for the compilation
        disabled_features = list of disabled features specified for the compilation
        srcs: the list of source files to be compiled.
        hdrs_map: the list of HdrsMapInfo providers that should be used during compilation,
        public_hdrs: list of headers needed for compilation of srcs and may be
            included by dependent rules transitively
        private_hdrs: list of headers needed for compilation of srcs and NOT to be
            included by dependent rules.
        deps: list of dependencies provided for the compilation,
        additional_inputs: list of additional files needed for compilation of srcs
        include_prefix: the prefix to add to the paths of the headers of this
            rule. When set, the headers in the hdrs attribute of this rule are
            accessible at is the value of this attribute prepended to their
            repository-relative path. The prefix in the strip_include_prefix
            attribute is removed before this prefix is added
        strip_include_prefix: the prefix to strip from the paths of the headers
            of this rule. When set, the headers in the hdrs attribute of this
            rule are accessible at their path with this prefix cut off.
            If it's a relative path, it's taken as a package-relative one.
            If it's an absolute one, it's understood as a repository-relative path.
            The prefix in the include_prefix attribute is added after this prefix is stripped.
        includes: search paths for header files referenced both by angle bracket and quotes.
            Usually passed with -I. Propagated to dependents transitively.
        quote_includes: search paths for header files referenced by quotes,
            e.g. #include "foo/bar/header.h". They can be either relative to the
            exec root or absolute. Usually passed with -iquote.
            Propagated to dependents transitively
        system_includes: search paths for header files referenced by angle brackets,
            e.g. #include <foo/bar/header.h>. They can be either relative to the
            exec root or absolute. Usually passed with -isystem.
            Propagated to dependents transitively.
        defines: set of defines needed to compile this target. Each define
            is a string. Propagated to dependents transitively.
        local_defines: set of defines needed to compile this target.
            Each define is a string. Not propagated to dependents transitively
        user_compile_flags: additional list of compilation options.
        conly_flags: additional list of compilation options for C compiles
        cxx_flags: additional list of compilation options for C++ compiles
        disallow_pic_outputs: whether PIC outputs should be created
        disallow_nopic_outputs: whether NOPIC outputs should be created
    """
    if not configure_features_func:
        fail("compile subrule requires for the 'configure_features_func' kwarg to be set!")

    cc_toolchain = find_cc_toolchain(sctx)

    hdrs_map_ctx = prepare_for_compilation(
        sctx,
        input_hdrs_map = hdrs_map,
        input_public_hdrs = public_hdrs,
        input_private_hdrs = private_hdrs,
        input_deps = deps,
        input_includes = includes,
    )

    _ = hdrs_map_ctx.hdrs_map
    public_hdrs = hdrs_map_ctx.public_hdrs
    private_hdrs = hdrs_map_ctx.private_hdrs
    includes = hdrs_map_ctx.includes
    deps = hdrs_map_ctx.deps

    compilation_contexts = [
        dep[CcInfo].compilation_context
        for dep in deps
        if CcInfo in dep
    ]

    # TODO: module_interfaces
    compilation_ctx, compilation_outputs = cc_common.compile(
        name = sctx.label.name,
        actions = sctx.actions,
        feature_configuration = configure_features_func(
            cc_toolchain,
            features = features,
            disabled_features = disabled_features,
        ),
        cc_toolchain = cc_toolchain,
        compilation_contexts = compilation_contexts,
        # Source files
        srcs = srcs,
        public_hdrs = public_hdrs,
        private_hdrs = private_hdrs,
        additional_inputs = additional_inputs,
        # Includes magic
        include_prefix = include_prefix,
        strip_include_prefix = strip_include_prefix,
        includes = includes,
        quote_includes = quote_includes,
        system_includes = system_includes,
        # Defines
        defines = defines,
        local_defines = local_defines,
        # Cflags
        user_compile_flags = user_compile_flags,
        conly_flags = conly_flags,
        cxx_flags = cxx_flags,
        disallow_pic_outputs = disallow_pic_outputs,
        disallow_nopic_outputs = disallow_nopic_outputs,
        # Apple framework
        framework_includes = [],
    )
    return compilation_ctx, compilation_outputs, hdrs_map_ctx

compile = subrule(
    implementation = _compile_impl,
    attrs = {},
    toolchains = use_cc_toolchain(),
)
