""" This module contains logic responsible for HdrsMap handling and compilation phase. """

load(
    "@rules_cc//cc:find_cc_toolchain.bzl",
    "find_cc_toolchain",
    "use_cc_toolchain",
)
load("@rules_cc_hdrs_map//cc_hdrs_map/actions:cc_helper.bzl", "cc_helper")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl", "HdrsMapInfo", "materialize_hdrs_mapping", "merge_hdrs_maps_info_from_deps")

def prepare_for_compilation(
        sctx,
        input_hdrs_map,
        input_hdrs,
        input_implementation_hdrs,
        input_deps,
        input_includes):
    """Materialize information from hdrs map.

    This function creates a epheremal directory, that contains all of the
    patterns specified within hdrs_map providers, thus making them all
    available under singular, temporary include statment.

    Args:
        sctx: subrule context
        input_hdrs_map: list of HdrsMapInfo which should be used for materialization of compilation context
        input_hdrs: direct headers provided to the action
        input_implementation_hdrs: direct headers provided to the action
        input_deps: dependencies specified for the action
        input_includes: include statements specified for the action
    """
    hdrs_map = input_hdrs_map if input_hdrs_map else {}
    hdrs = [h for h in input_hdrs]
    implementation_hdrs = [h for h in input_implementation_hdrs]
    deps = [d for d in input_deps]

    # Merge with deps
    deps_pub_hdrs, deps_prv_hdrs, hdrs_map, deps_deps = merge_hdrs_maps_info_from_deps(
        deps,
        hdrs_map,
    )
    hdrs = depset(direct = hdrs, transitive = [deps_pub_hdrs])
    implementation_hdrs = depset(direct = implementation_hdrs, transitive = [deps_prv_hdrs])
    deps = depset(direct = deps, transitive = [deps_deps])

    # Materialize mappings
    hdrs_extra_include_path, hdrs_extra_files = materialize_hdrs_mapping(
        sctx.label,
        sctx.actions,
        hdrs_map,
        hdrs,
    )
    if hdrs_extra_files:
        hdrs = depset(direct = hdrs_extra_files, transitive = [hdrs])

    implementation_hdrs_extra_include_path, implementation_hdrs_extra_files = materialize_hdrs_mapping(
        sctx.label,
        sctx.actions,
        hdrs_map,
        implementation_hdrs,
    )
    if implementation_hdrs_extra_files:
        implementation_hdrs = depset(direct = implementation_hdrs_extra_files, transitive = [implementation_hdrs])

    includes = input_includes if input_includes else []
    if hdrs_extra_include_path:
        includes.append(hdrs_extra_include_path)
    if implementation_hdrs_extra_include_path:
        includes.append(implementation_hdrs_extra_include_path)

    return struct(
        hdrs_map = hdrs_map,
        hdrs = hdrs,
        implementation_hdrs = implementation_hdrs,
        includes = includes,
        deps = deps,
    )

def _compile_impl(
        sctx,
        extra_ctx_members = None,
        configure_features_func = None,
        features = [],
        disabled_features = [],
        # Sources
        srcs = [],
        hdrs_map = {},
        hdrs = [],
        implementation_hdrs = [],
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
        hdrs: list of headers needed for compilation of srcs and may be
            included by dependent rules transitively
        implementation_hdrs: list of headers needed for compilation of srcs and NOT to be
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
        input_hdrs = hdrs,
        input_implementation_hdrs = implementation_hdrs + cc_helper.extract_headers(srcs),
        input_deps = deps,
        input_includes = includes,
    )

    _ = hdrs_map_ctx.hdrs_map
    hdrs = hdrs_map_ctx.hdrs
    implementation_hdrs = hdrs_map_ctx.implementation_hdrs
    includes = hdrs_map_ctx.includes
    deps = hdrs_map_ctx.deps.to_list()

    compilation_contexts = [
        dep[CcInfo].compilation_context
        for dep in deps
        if CcInfo in dep
    ]

    feature_configuration = configure_features_func(
        cc_toolchain,
        features = features,
        disabled_features = disabled_features,
    )

    # Additional make variable substitutions
    amvs = cc_helper.get_toolchain_global_make_variables(cc_toolchain)
    amvs.update(cc_helper.get_cc_flags_make_variable(cc_toolchain, feature_configuration))

    compilation_ctx, compilation_outputs = cc_common.compile(
        name = sctx.label.name,
        actions = sctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        compilation_contexts = compilation_contexts,
        # Error in check_private_api: file '@@rules_cc_hdrs_map+//cc_hdrs_map/actions:compile.bzl' cannot use private API :<
        # Therfore: no implementation_deps
        # implementation_compilation_contexts = None,
        #
        # Source files
        # TODO: Guard against duplicates
        srcs = cc_helper.extract_sources(srcs),
        # TODO: Guard against duplicates, read headers from srcs
        public_hdrs = hdrs.to_list(),
        private_hdrs = implementation_hdrs.to_list(),
        additional_inputs = [f for t in additional_inputs for f in t.files],
        # Includes magic
        include_prefix = include_prefix,
        strip_include_prefix = strip_include_prefix,
        includes = includes,
        # For now, the 2 includes below are effectively noop
        quote_includes = quote_includes,
        system_includes = system_includes,
        # Defines
        defines = cc_helper.get_compilation_defines(sctx, extra_ctx_members, defines, deps, amvs, []),
        local_defines = cc_helper.get_compilation_defines(sctx, extra_ctx_members, local_defines, deps, amvs, additional_inputs) + cc_helper.get_local_defines_for_runfiles_lookup(sctx, deps),
        # Cflags
        user_compile_flags = cc_helper.get_compilation_opts(sctx, extra_ctx_members, user_compile_flags, feature_configuration, amvs, additional_inputs),
        conly_flags = cc_helper.get_compilation_opts(sctx, extra_ctx_members, conly_flags, feature_configuration, amvs, additional_inputs),
        cxx_flags = cc_helper.get_compilation_opts(sctx, extra_ctx_members, cxx_flags, feature_configuration, amvs, additional_inputs),
        disallow_pic_outputs = disallow_pic_outputs,
        disallow_nopic_outputs = disallow_nopic_outputs,
        # Apple framework
        framework_includes = [],
        # TODO: Implment module interfaces
    )
    return compilation_ctx, compilation_outputs, hdrs_map_ctx

compile = subrule(
    implementation = _compile_impl,
    attrs = {},
    toolchains = use_cc_toolchain(),
)
