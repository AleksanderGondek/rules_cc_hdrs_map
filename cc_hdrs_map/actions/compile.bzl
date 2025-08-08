""" This module contains logic responsible for HdrsMap handling and compilation phase. """

load(
    "@rules_cc//cc:find_cc_toolchain.bzl",
    "find_cc_toolchain",
    "use_cc_toolchain",
)
load("@rules_cc_hdrs_map//cc_hdrs_map/actions:cc_helper.bzl", "cc_helper")

def _compile_impl(
        sctx,
        cc_feature_configuration_func = None,
        features = [],
        disabled_features = [],
        # Sources
        srcs = [],
        hdrs_map = None,
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
        cc_feature_configuration_func: function that will provide [FeatureConfiguration](https://bazel.build/rules/lib/builtins/FeatureConfiguration.html)
        features: list of features specified for the compilation
        disabled_features = list of disabled features specified for the compilation
        srcs: the list of source files to be compiled.
        hdrs_map: instance of hdrs_map struct, describing intended mapping for the header files.
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
    if not cc_feature_configuration_func:
        fail("compile subrule requires for the 'cc_feature_configuration_func' kwarg to be set!")

    cc_toolchain = find_cc_toolchain(sctx)

    hdrs_map_ctx = cc_helper.prepare_for_compilation(
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

    cc_feature_configuration = cc_feature_configuration_func(
        cc_toolchain,
        features = features,
        disabled_features = disabled_features,
    )

    compilation_ctx, compilation_outputs = cc_common.compile(
        name = sctx.label.name,
        actions = sctx.actions,
        feature_configuration = cc_feature_configuration,
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
        additional_inputs = depset([], transitive = [i.files for i in additional_inputs]).to_list(),
        # Includes magic
        include_prefix = include_prefix,
        strip_include_prefix = strip_include_prefix,
        includes = includes,
        # For now, the 2 includes below are effectively noop
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
        # TODO: Implment module interfaces
    )
    return compilation_ctx, compilation_outputs, hdrs_map_ctx

compile = subrule(
    implementation = _compile_impl,
    attrs = {},
    toolchains = use_cc_toolchain(),
)
