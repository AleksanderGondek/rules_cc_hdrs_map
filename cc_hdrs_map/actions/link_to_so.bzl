""" This module contains logic responsible for linking into .so file. """

load(
    "@rules_cc//cc:find_cc_toolchain.bzl",
    "find_cc_toolchain",
    "use_cc_toolchain",
)

def _link_to_so_impl(
        sctx,
        compilation_outputs,
        configure_features_func = [],
        features = [],
        disabled_features = [],
        deps = [],
        disallow_static_libraries = False,
        disallow_dynamic_library = False,
        user_link_flags = [],
        alwayslink = False,
        additional_inputs = [],
        variables_extension = {}):
    """Link into a shared object library.

    This subrule runs the linking phase of the compilation process,
    creating a shared object library.

    TODO: Support for CcSharedLibraryInfo and friends is required!

    Args:
        sctx: subrule context
        configure_features_func: function that will provide [FeatureConfiguration](https://bazel.build/rules/lib/builtins/FeatureConfiguration.html)
        features: list of features specified for the linking
        disabled_features = list of disabled features specified for the linking
        deps: list of dependencies provided for the linking
        disallow_static_libraries: whether static libraries should be created
        disallow_dynamic_library: whether a dynamic library should be created
        user_link_flags = additional list of linking options
        alwayslink = whether this library should always be linked
        additional_inputs = for additional inputs to the linking action, e.g.: linking scripts
        variables_extension = additional variables to pass to the toolchain configuration when creating link command line
    """
    if not configure_features_func:
        fail("link_to_so subrule requires for the 'configure_features_func' kwarg to be set!")

    cc_toolchain = find_cc_toolchain(sctx)

    linking_contexts = [
        dep[CcInfo].linking_context
        for dep in deps
        if CcInfo in dep
    ]

    return cc_common.create_linking_context_from_compilation_outputs(
        actions = sctx.actions,
        # Opinionated logic:
        # create_linking_context_from_compilation_outputs will
        # prepend the 'lib' to the output name - which makes sense,
        # but if and only if the target does not yet has that prefix.
        # Without little trimming here, the output library will be named 'liblib<name>'
        name = sctx.label.name.removeprefix("lib"),
        feature_configuration = configure_features_func(
            cc_toolchain,
            features = features,
            disabled_features = disabled_features,
        ),
        cc_toolchain = cc_toolchain,
        disallow_static_libraries = disallow_static_libraries,
        disallow_dynamic_library = disallow_dynamic_library,
        compilation_outputs = compilation_outputs,
        linking_contexts = linking_contexts,
        user_link_flags = user_link_flags,
        alwayslink = alwayslink,
        additional_inputs = additional_inputs,
        variables_extension = variables_extension,
    )

link_to_so = subrule(
    implementation = _link_to_so_impl,
    attrs = {},
    toolchains = use_cc_toolchain(),
)
