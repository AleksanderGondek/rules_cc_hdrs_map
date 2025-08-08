""" This module contains logic responsible for creation of executable binary. """

load(
    "@rules_cc//cc:find_cc_toolchain.bzl",
    "find_cc_toolchain",
    "use_cc_toolchain",
)
load("@rules_cc_hdrs_map//cc_hdrs_map/actions:cc_helper.bzl", "cc_helper")

def _link_to_binary_impl(
        sctx,
        compilation_outputs,
        cc_feature_configuration_func = [],
        features = [],
        disabled_features = [],
        deps = [],
        user_link_flags = [],
        stamp = 0,
        additional_inputs = [],
        variables_extension = {}):
    """Create execute binary.

    This subrule runs the linking phase of the compilation process,
    resulting in creation of an executable file.

    The intended differentiator of the outputs, is the capability
    to automatically gather all specified dynamic dependencies and
    pass them on to the 'bazel run' of the target.

    TODO: aforementioned gathering logic.

    Args:
        sctx: subrule context
        cc_feature_configuration_func: function that will provide [FeatureConfiguration](https://bazel.build/rules/lib/builtins/FeatureConfiguration.html)
        features: list of features specified for the linking
        disabled_features = list of disabled features specified for the linking
        deps: list of dependencies provided for the linking
        user_link_flags: additional list of linker options.
        stamp: whether to include build information in the linked executable,
            if output_type is 'executable'.If 1, build information is
            always included. If 0 (the default build information is always excluded.
            If -1, uses the default behavior, which may be overridden by
            the --[no]stamp flag. This should be unset (or set to 0) when
            generating the executable output for test rules.
        additional_inputs: for additional inputs to the linking action, e.g.: linking scripts
        variables_extension: additional variables to pass to the toolchain configuration when create link command line
    """
    if not cc_feature_configuration_func:
        fail("link_to_binary subrule requires for the 'cc_feature_configuration_func' kwarg to be set!")

    cc_toolchain = find_cc_toolchain(sctx)

    # TODO: dedup with cc_so
    linking_contexts = []
    linking_inputs = []
    transitive_dynamic_deps = []
    transitive_sols = []

    for dep in deps:
        if CcInfo in dep:
            linking_contexts.append(dep[CcInfo].linking_context)
            continue
        if CcSharedLibraryInfo in dep:
            dynamic_dep = dep[CcSharedLibraryInfo]
            linking_inputs.append(dynamic_dep.linker_input)
            transitive_dynamic_deps.append(dynamic_dep.dynamic_deps)

    for transitive_dynamic_dep in depset(transitive = transitive_dynamic_deps).to_list():
        for transitive_dynamic_lib in transitive_dynamic_dep.linker_input.libraries:
            transitive_sols.append(transitive_dynamic_lib.dynamic_library)

    linking_contexts.append(
        cc_common.create_linking_context(
            linker_inputs = depset(
                direct = linking_inputs,
                order = "topological",
            ),
        ),
    )

    return cc_common.link(
        actions = sctx.actions,
        name = sctx.label.name,
        feature_configuration = cc_feature_configuration_func(
            cc_toolchain,
            features = features,
            disabled_features = disabled_features,
        ),
        cc_toolchain = cc_toolchain,
        output_type = "executable",
        link_deps_statically = True,
        compilation_outputs = compilation_outputs,
        linking_contexts = linking_contexts,
        user_link_flags = user_link_flags,
        stamp = stamp,
        # Adding transitive sols makes the compilation
        # work with --unresolved-symbols='report-all'
        additional_inputs = depset(transitive_sols, transitive = [i.files for i in additional_inputs]),
        variables_extension = variables_extension,
    )

link_to_binary = subrule(
    implementation = _link_to_binary_impl,
    attrs = {},
    toolchains = use_cc_toolchain(),
)
