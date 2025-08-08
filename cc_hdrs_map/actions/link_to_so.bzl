""" This module contains logic responsible for linking into .so file. """

load(
    "@rules_cc//cc:find_cc_toolchain.bzl",
    "find_cc_toolchain",
    "use_cc_toolchain",
)
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("@rules_cc//cc/common:cc_shared_library_info.bzl", "CcSharedLibraryInfo")
load("@rules_cc_hdrs_map//cc_hdrs_map/actions:cc_helper.bzl", "cc_helper")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:cc_shared_library_info.bzl", "merge_cc_shared_library_infos")

def _link_to_so_impl(
        sctx,
        compilation_outputs,
        cc_feature_configuration_func = [],
        features = [],
        disabled_features = [],
        deps = [],
        shared_lib_name = None,
        user_link_flags = [],
        additional_inputs = [],
        variables_extension = {}):
    """Link into a shared object library.

    This subrule runs the linking phase of the compilation process,
    creating a shared object library.

    Args:
        sctx: subrule context
        cc_configuration_func: function that will provide [FeatureConfiguration](https://bazel.build/rules/lib/builtins/FeatureConfiguration.html)
        features: list of features specified for the linking
        disabled_features: list of disabled features specified for the linking
        deps: list of dependencies provided for the linking
        shared_lib_name: overwrite the default name of the library
        user_link_flags: additional list of linking options
        additional_inputs: for additional inputs to the linking action, e.g.: linking scripts
        variables_extension: additional variables to pass to the toolchain configuration when creating link command line
    """
    if not cc_feature_configuration_func:
        fail("link_to_so subrule requires for the 'cc_feature_configuration_func' kwarg to be set!")

    cc_toolchain = find_cc_toolchain(sctx)

    sol_name = shared_lib_name if shared_lib_name else sctx.label.name

    # Opinionated part: prevent any liblibName or libName.so.so or libName.so.test.so
    sol_name = sol_name.removeprefix("lib").replace(".so.", ".").removesuffix(".so")

    # TODO: dedup with cc_bin
    linking_contexts = []
    linking_inputs = []
    transitive_sols = []
    transitive_dynamic_deps = []

    for dep in deps:
        if CcInfo in dep:
            linking_contexts.append(dep[CcInfo].linking_context)
        if not CcSharedLibraryInfo in dep:
            continue
        dynamic_dep = dep[CcSharedLibraryInfo]
        linking_inputs.append(dynamic_dep.linker_input)
        transitive_dynamic_deps.append(dynamic_dep.dynamic_deps)

    for transitive_dynamic_dep in depset(transitive = transitive_dynamic_deps).to_list():
        for transitive_dynamic_lib in transitive_dynamic_dep.linker_input.libraries:
            transitive_sols.append(transitive_dynamic_lib.dynamic_library)

    linking_outputs = cc_common.link(
        actions = sctx.actions,
        name = sol_name,
        feature_configuration = cc_feature_configuration_func(
            cc_toolchain,
            features = features + ["force_no_whole_archive"],
            disabled_features = disabled_features,
        ),
        cc_toolchain = cc_toolchain,
        output_type = "dynamic_library",
        link_deps_statically = True,
        compilation_outputs = compilation_outputs,
        linking_contexts = [cc_common.create_linking_context(
            linker_inputs = depset(direct = linking_inputs, order = "topological"),
        )] + linking_contexts,
        user_link_flags = user_link_flags,
        stamp = 0,
        # I am leaving this in because I am petty
        # Error in check_private_api: file '@@rules_cc_hdrs_map+//cc_hdrs_map/actions:link_to_so.bzl' cannot use private API
        # main_output = sctx.actions.declare_file(shared_lib_name) if shared_lib_name else None,
        additional_inputs = depset(transitive_sols, transitive = [i.files for i in additional_inputs]),
        variables_extension = variables_extension,
    )

    return (merge_cc_shared_library_infos(
        targets = deps,
        exports = {str(sctx.label): True},
        linker_input = cc_common.create_linker_input(
            owner = sctx.label,
            libraries = depset([linking_outputs.library_to_link]),
        ),
        link_once_static_libs = [],
    ), linking_outputs)

link_to_so = subrule(
    implementation = _link_to_so_impl,
    attrs = {},
    toolchains = use_cc_toolchain(),
)
