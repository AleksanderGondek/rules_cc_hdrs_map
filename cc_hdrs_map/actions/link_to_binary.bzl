""" This module contains logic responsible for creation of executable binary. """

load(
    "@rules_cc//cc:find_cc_toolchain.bzl",
    "find_cc_toolchain",
    "use_cc_toolchain",
)

def _link_to_binary_impl(
        sctx,
        compilation_outputs,
        configure_features_func = [],
        features = [],
        disabled_features = [],
        deps = [],
        link_deps_statically = True,
        user_link_flags = [],
        stamp = 0,
        additional_inputs = [],
        additional_outputs = [],
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
        configure_features_func: function that will provide [FeatureConfiguration](https://bazel.build/rules/lib/builtins/FeatureConfiguration.html)
        features: list of features specified for the linking
        disabled_features = list of disabled features specified for the linking
        deps: list of dependencies provided for the linking
        link_deps_statically: True to link dependencies statically, False dynamically.
        user_link_flags: additional list of linker options.
        stamp: whether to include build information in the linked executable,
            if output_type is 'executable'.If 1, build information is
            always included. If 0 (the default build information is always excluded.
            If -1, uses the default behavior, which may be overridden by
            the --[no]stamp flag. This should be unset (or set to 0) when
            generating the executable output for test rules.
        additional_inputs: for additional inputs to the linking action, e.g.: linking scripts
        additional_outputs: for additional outputs to the linking action, e.g.: map files.
        variables_extension: additional variables to pass to the toolchain configuration when create link command line
    """
    if not configure_features_func:
        fail("link_to_binary subrule requires for the 'configure_features_func' kwarg to be set!")

    cc_toolchain = find_cc_toolchain(sctx)

    linking_contexts = [
        dep[CcInfo].linking_context
        for dep in deps
        if CcInfo in dep
    ]

    return cc_common.link(
        actions = sctx.actions,
        name = sctx.label.name,
        feature_configuration = configure_features_func(
            cc_toolchain,
            features = features,
            disabled_features = disabled_features,
        ),
        cc_toolchain = cc_toolchain,
        output_type = "executable",
        link_deps_statically = link_deps_statically,
        compilation_outputs = compilation_outputs,
        linking_contexts = linking_contexts,
        user_link_flags = user_link_flags,
        stamp = stamp,
        additional_inputs = additional_inputs,
    )

link_to_binary = subrule(
    implementation = _link_to_binary_impl,
    attrs = {},
    toolchains = use_cc_toolchain(),
)
