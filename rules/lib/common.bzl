""" Module encompassing `cc_common`-related operations (i.e. compilation). """

load(
    "@bazel_tools//tools/build_defs/cc:action_names.bzl",
    "CPP_LINK_STATIC_LIBRARY_ACTION_NAME",
)
load(
    "@rules_cc_hdrs_map//rules:lib/hdrs_map.bzl",
    "materialize_hdrs_mapping",
    "merge_hdr_maps_info_from_deps",
)

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

def prepare_for_compilation(
        invoker_label,
        actions,
        is_windows,
        cc_toolchain,
        feature_configuration,
        input_hdrs_map,
        input_public_hdrs,
        input_private_hdrs,
        input_deps,
        input_includes):
    """ To be described. """

    hdrs_map = input_hdrs_map if input_hdrs_map else {}
    public_hdrs = [h for h in input_public_hdrs]
    private_hdrs = [h for h in input_private_hdrs]
    deps = [d for d in input_deps]

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
        invoker_label,
        actions,
        is_windows,
        hdrs_map,
        public_hdrs,
    )
    if public_hdrs_extra_files:
        public_hdrs.extend(public_hdrs_extra_files)

    private_hdrs_extra_include_path, private_hdrs_extra_files = materialize_hdrs_mapping(
        invoker_label,
        actions,
        is_windows,
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
        user_compile_flags = []):
    """ To be described. """
    compilation_contexts = [
        dep[CcInfo].compilation_context
        for dep in deps
        if CcInfo in dep
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

def link_to_so(
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
        disallow_dynamic_library = False):
    """ To be described. """
    linking_contexts = [
        dep[CcInfo].linking_context
        for dep in deps
        if CcInfo in dep
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

# This function is borrowed from:
# https://github.com/kkiningh/rules_verilator/blob/5d4e8da0fde91bddd5d71baf10eb35d3406aa1c8/verilator/internal/cc_actions.bzl#L9
def link_to_archive(
        invoker_label,
        actions,
        cc_toolchain,
        feature_configuration,
        compilation_outputs,
        deps = [],
        user_link_flags = []):
    """ To be described. """
    linking_contexts = [
        dep[CcInfo].linking_context
        for dep in deps
        if CcInfo in dep
    ]

    static_library = actions.declare_file(
        "lib{name}.a".format(name = invoker_label.name),
    )
    link_tool = cc_common.get_tool_for_action(
        feature_configuration = feature_configuration,
        action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
    )
    link_variables = cc_common.create_link_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        output_file = static_library.path,
        is_using_linker = False,
        is_linking_dynamic_library = False,
        user_link_flags = user_link_flags,
    )
    link_env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
        variables = link_variables,
    )
    link_flags = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
        variables = link_variables,
    )

    # Dependency libraries to link.
    # TODO: Not clear how to remove to_list here, see
    # https://github.com/bazelbuild/bazel/issues/8118#issuecomment-487175926
    dep_objects = []
    for context in linking_contexts:
        for linker_input in context.linker_inputs.to_list():
            for lib in linker_input.libraries:
                dep_objects += lib.objects

    # Run linker
    args = actions.args()
    args.add_all(link_flags)
    args.add_all(compilation_outputs.objects)
    args.add_all(dep_objects)
    actions.run(
        outputs = [static_library],
        inputs = depset(
            direct = compilation_outputs.objects + dep_objects,
            transitive = [cc_toolchain.all_files],
        ),
        executable = link_tool,
        arguments = [args],
        mnemonic = "CCHdrsMapStaticLink",
        progress_message = "Linking {}".format(static_library.short_path),
        env = link_env,
    )

    # Build the linking info provider
    linker_input = cc_common.create_linker_input(
        owner = invoker_label,
        libraries = depset(direct = [
            cc_common.create_library_to_link(
                actions = actions,
                feature_configuration = feature_configuration,
                cc_toolchain = cc_toolchain,
                static_library = static_library,
            ),
        ]),
        user_link_flags = user_link_flags,
    )
    linking_context = cc_common.create_linking_context(
        linker_inputs = depset(direct = [linker_input]),
    )

    # Merge linking info for downstream rules
    linking_contexts.append(linking_context)
    cc_infos = [CcInfo(linking_context = linking_context) for linking_context in linking_contexts]
    merged_cc_info = cc_common.merge_cc_infos(
        cc_infos = cc_infos,
    )

    # Workaround to emulate CcLinkingInfo (the return value of cc_common.link)
    return struct(
        linking_context = merged_cc_info.linking_context,
        cc_linking_outputs = struct(
            static_libraries = [static_library],
        ),
    )

def link_to_binary(
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
        additional_inputs = []):
    """ To be described. """
    linking_contexts = [
        dep[CcInfo].linking_context
        for dep in deps
        if CcInfo in dep
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
