"""" This module contains logic responsible for linking into .a file. """

load("@rules_cc//cc:action_names.bzl", "CPP_LINK_STATIC_LIBRARY_ACTION_NAME")
load(
    "@rules_cc//cc:find_cc_toolchain.bzl",
    "find_cc_toolchain",
    "use_cc_toolchain",
)

def _link_to_archive_impl(
        sctx,
        compilation_outputs,
        extra_ctx_members = None,
        configure_features_func = [],
        features = [],
        disabled_features = [],
        deps = [],
        user_link_flags = [],
        archive_lib_name = None):
    """Link into an archive file.

    This subrule runs the linker to create an .archive file.

    Args:
        sctx: subrule context
        configure_features_func: function that will provide [FeatureConfiguration](https://bazel.build/rules/lib/builtins/FeatureConfiguration.html)
        features: list of features specified for the linking
        disabled_features = list of disabled features specified for the linking
        deps: list of dependencies provided for the linking
        user_link_flags = additional list of linking options
        archive_lib_name = name of the archive file that should be created
    """
    if not configure_features_func:
        fail("link_to_archive subrule requires for the 'configure_features_func' kwarg to be set!")

    cc_toolchain = find_cc_toolchain(sctx)

    archive_lib_name = archive_lib_name if archive_lib_name else sctx.label.name

    # Opinionated part: prevent any liblibName or libName.a.a or libName.a.test.a
    archive_lib_name = archive_lib_name.removeprefix("lib").replace(".a.", ".").removesuffix(".a")

    features_configuration = configure_features_func(
        cc_toolchain,
        features = features,
        disabled_features = disabled_features,
    )
    linking_contexts = [
        dep[CcInfo].linking_context
        for dep in deps
        if CcInfo in dep
    ]

    static_library = sctx.actions.declare_file(
        "lib{name}.a".format(name = archive_lib_name),
    )

    link_tool = cc_common.get_tool_for_action(
        feature_configuration = features_configuration,
        action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
    )
    link_variables = cc_common.create_link_variables(
        feature_configuration = features_configuration,
        cc_toolchain = cc_toolchain,
        output_file = static_library.path,
        is_using_linker = False,
        is_linking_dynamic_library = False,
        user_link_flags = user_link_flags,
    )
    link_env = cc_common.get_environment_variables(
        feature_configuration = features_configuration,
        action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
        variables = link_variables,
    )
    link_flags = cc_common.get_memory_inefficient_command_line(
        feature_configuration = features_configuration,
        action_name = CPP_LINK_STATIC_LIBRARY_ACTION_NAME,
        variables = link_variables,
    )

    # Dependency libraries to link.
    dep_objects = []
    linker_inputs = []
    for context in linking_contexts:
        linker_inputs.append(context.linker_inputs)

    for linker_input in depset(transitive = linker_inputs).to_list():
        for lib in linker_input.libraries:
            dep_objects += lib.objects

    # Run linker
    args = sctx.actions.args()
    args.add_all(link_flags)
    args.add_all(compilation_outputs.pic_objects)
    args.add_all(dep_objects)

    sctx.actions.run(
        outputs = [static_library],
        inputs = depset(
            direct = compilation_outputs.pic_objects + dep_objects,
            transitive = [cc_toolchain.all_files],
        ),
        executable = link_tool,
        arguments = [args],
        mnemonic = "CCHdrsMapStaticLink",
        progress_message = "Linking {}".format(static_library.short_path),
        # TODO: improve
        # This is a quirk of my toolchain / platfoorm
        # otherwise realpath, dirname cannot be found
        env = link_env | {"PATH": link_env.get("PATH", "") + ":/bin:/usr/bin"},
    )

    # Build the linking info provider
    linker_input = cc_common.create_linker_input(
        owner = sctx.label,
        libraries = depset(direct = [
            cc_common.create_library_to_link(
                actions = sctx.actions,
                feature_configuration = features_configuration,
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

link_to_archive = subrule(
    implementation = _link_to_archive_impl,
    attrs = {},
    toolchains = use_cc_toolchain(),
)
