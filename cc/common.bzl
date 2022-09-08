""" To be described. """

def get_feature_configuration(ctx, cc_toolchain):
    """ To be described. """
    return cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        # Valid only for Bazel > 5.1.1
        # language = "c++",
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

def compile(
    name,
    actions,
    cc_toolchain,
    feature_configuration,
    srcs = [],
    public_hdrs = [],
    private_hdrs = [],
    deps = [],
    # Includes
    include_prefix = "",
    strip_include_prefix = "",
    includes = [],
    quote_includes = [],
    system_includes = [],
    # Other
    defines = [],
    local_defines = [],
    user_compile_flags = [],
):
    """ To be described. """
    compilation_contexts = [
        dep[CcInfo].compilation_context for dep in deps if CcInfo in dep
    ]
    compilation_ctx, compilation_outputs = cc_common.compile(
        name = name,
        actions = actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        compilation_contexts = compilation_contexts,
        # Source files
        srcs = srcs,
        public_hdrs = public_hdrs,
        private_hdrs = private_hdrs,
        # Includes magic
        include_prefix = include_prefix,
        strip_include_prefix = strip_include_prefix,
        includes = includes,
        quote_includes = quote_includes,
        system_includes = system_includes,
        # Other        
        defines = defines,
        local_defines = local_defines,
        user_compile_flags = user_compile_flags,
    )

    return compilation_ctx, compilation_outputs

def create_shared_library(
    name,
    actions,
    cc_toolchain,
    feature_configuration,
    compilation_outputs,
    deps = [],
    user_link_flags = [],
    alwayslink = False,
    additional_inputs = [],
    disallow_static_libraries = False,
    disallow_dynamic_library = False,
):
    """ To be described. """
    linking_contexts = [
        dep[CcInfo].linking_context for dep in deps if CcInfo in dep
    ]
    linking_context, linking_output = cc_common.create_linking_context_from_compilation_outputs(
        actions = actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        compilation_outputs = compilation_outputs,
        linking_contexts = linking_contexts,
        name = name,
        user_link_flags = user_link_flags,
        alwayslink = alwayslink,
        additional_inputs = additional_inputs,
        disallow_static_libraries = disallow_static_libraries,
        disallow_dynamic_library = disallow_dynamic_library,
    )

    return linking_context, linking_output

def link(
    name,
    actions,
    cc_toolchain,
    feature_configuration,
    compilation_outputs,
    deps = [],
    output_type = "executable",
    user_link_flags = [],
    link_deps_statically = True,
    stamp = 0,
    additional_inputs = [],
):
    """ To be described. """
    linking_contexts = [
        dep[CcInfo].linking_context for dep in deps if CcInfo in dep
    ]    
    linking_output = cc_common.link(
        actions = actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        compilation_outputs = compilation_outputs,
        linking_contexts = linking_contexts,
        name = name,
        output_type = output_type,
        user_link_flags = [],
        link_deps_statically = link_deps_statically,
        stamp = stamp,
        additional_inputs = additional_inputs,
    )

    return linking_output
