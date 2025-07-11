""" This module contains logic responsible for linking into .so file. """

load(
    "@rules_cc//cc:find_cc_toolchain.bzl",
    "find_cc_toolchain",
    "use_cc_toolchain",
)
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("@rules_cc//cc/common:cc_shared_library_info.bzl", "CcSharedLibraryInfo")

# Sharing is caring
# https://github.com/bazelbuild/bazel/blob/49e43bbd4a3a3aa5f0f00158dff15914b69b6e85/src/main/starlark/builtins_bzl/common/cc/cc_shared_library.bzl#L222
def _merge_cc_shared_library_infos(deps):
    dynamic_deps = []
    transitive_dynamic_deps = []
    for dep in deps:
        if not CcSharedLibraryInfo in dep:
            continue

        dynamic_dep_entry = struct(
            exports = dep[CcSharedLibraryInfo].exports,
            linker_input = dep[CcSharedLibraryInfo].linker_input,
            link_once_static_libs = dep[CcSharedLibraryInfo].link_once_static_libs,
        )
        dynamic_deps.append(dynamic_dep_entry)
        transitive_dynamic_deps.append(dep[CcSharedLibraryInfo].dynamic_deps)

    return depset(direct = dynamic_deps, transitive = transitive_dynamic_deps, order = "topological")

def _link_to_so_impl(
        sctx,
        compilation_outputs,
        configure_features_func = [],
        features = [],
        disabled_features = [],
        deps = [],
        disallow_static_libraries = True,
        disallow_dynamic_library = False,
        shared_lib_name = None,
        user_link_flags = [],
        alwayslink = True,
        additional_inputs = [],
        variables_extension = {}):
    """Link into a shared object library.

    This subrule runs the linking phase of the compilation process,
    creating a shared object library.

    Args:
        sctx: subrule context
        configure_features_func: function that will provide [FeatureConfiguration](https://bazel.build/rules/lib/builtins/FeatureConfiguration.html)
        features: list of features specified for the linking
        disabled_features: list of disabled features specified for the linking
        deps: list of dependencies provided for the linking
        disallow_static_libraries: whether static libraries should be created
        disallow_dynamic_library: whether a dynamic library should be created
        shared_lib_name: overwrite the default name of the library
        user_link_flags: additional list of linking options
        alwayslink: whether this library should always be linked
        additional_inputs: for additional inputs to the linking action, e.g.: linking scripts
        variables_extension: additional variables to pass to the toolchain configuration when creating link command line
    """
    if not configure_features_func:
        fail("link_to_so subrule requires for the 'configure_features_func' kwarg to be set!")

    cc_toolchain = find_cc_toolchain(sctx)

    sol_name = shared_lib_name if shared_lib_name else sctx.label.name
    sol_name = sol_name.removeprefix("lib")

    # TODO: Linker inputs from CcInfo ?
    # TODO: dedup with cc_bin
    linking_inputs = []
    transitive_sols = []

    for dep in deps:
        if not CcSharedLibraryInfo in dep:
            continue
        dynamic_dep = dep[CcSharedLibraryInfo]
        linking_inputs.append(dynamic_dep.linker_input)

        for transitive_dynamic_dep in dynamic_dep.dynamic_deps.to_list():
            for transitive_dynamic_lib in transitive_dynamic_dep.linker_input.libraries:
                transitive_sols.append(transitive_dynamic_lib.dynamic_library)

    linking_outputs = cc_common.link(
        actions = sctx.actions,
        name = sol_name,
        feature_configuration = configure_features_func(
            cc_toolchain,
            features = features + ["force_no_whole_archive"],
            disabled_features = disabled_features,
        ),
        cc_toolchain = cc_toolchain,
        output_type = "dynamic_library",
        link_deps_statically = False,
        compilation_outputs = compilation_outputs,
        linking_contexts = [cc_common.create_linking_context(
            linker_inputs = depset(direct = linking_inputs, order = "topological"),
        )],
        user_link_flags = user_link_flags,
        stamp = 0,
        # I am leaving this in because I am petty
        # Error in check_private_api: file '@@rules_cc_hdrs_map+//cc_hdrs_map/actions:link_to_so.bzl' cannot use private API
        # main_output = sctx.actions.declare_file(shared_lib_name) if shared_lib_name else None,
        additional_inputs = additional_inputs + transitive_sols,
    )

    linker_input = cc_common.create_linker_input(
        owner = sctx.label,
        libraries = depset([linking_outputs.library_to_link]),
    )

    # TODO: This is extremely naive
    exports = {str(sctx.label): True}
    for dep in deps:
        if not CcInfo in dep:
            continue
        exports[str(dep.label)] = True

    return struct(
        dynamic_deps = _merge_cc_shared_library_infos(deps),
        exports = exports,
        linker_input = linker_input,
        link_once_static_libs = None,
    ), linking_outputs

link_to_so = subrule(
    implementation = _link_to_so_impl,
    attrs = {},
    toolchains = use_cc_toolchain(),
)
