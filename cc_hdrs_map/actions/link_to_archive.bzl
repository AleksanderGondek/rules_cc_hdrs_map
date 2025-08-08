"""" This module contains logic responsible for linking into .a file. """

load("@rules_cc//cc:action_names.bzl", "CPP_LINK_STATIC_LIBRARY_ACTION_NAME")
load(
    "@rules_cc//cc:find_cc_toolchain.bzl",
    "find_cc_toolchain",
    "use_cc_toolchain",
)
load("@rules_cc_hdrs_map//cc_hdrs_map/actions:cc_helper.bzl", "cc_helper")

def _link_to_archive_impl(
        sctx,
        compilation_outputs,
        cc_feature_configuration_func = [],
        features = [],
        disabled_features = [],
        deps = [],
        archive_lib_name = None,
        user_link_flags = [],
        additional_inputs = [],
        variables_extension = {}):
    """Link into an archive file.

    This subrule runs the linker to create an .archive file.

    Args:
        sctx: subrule context
        cc_feature_configuration_func: function that will provide [FeatureConfiguration](https://bazel.build/rules/lib/builtins/FeatureConfiguration.html)
        features: list of features specified for the linking
        disabled_features = list of disabled features specified for the linking
        deps: list of dependencies provided for the linking
        user_link_flags = additional list of linking options
        archive_lib_name = name of the archive file that should be created
        additional_inputs: for additional inputs to the linking action, e.g.: linking scripts
        variables_extension: additional variables to pass to the toolchain configuration when creating link command line
    """
    if not cc_feature_configuration_func:
        fail("link_to_archive subrule requires for the 'cc_feature_configuration_func' kwarg to be set!")

    cc_toolchain = find_cc_toolchain(sctx)

    archive_lib_name = archive_lib_name if archive_lib_name else sctx.label.name

    # Opinionated part: prevent any liblibName or libName.a.a or libName.a.test.a
    archive_lib_name = archive_lib_name.removeprefix("lib").replace(".a.", ".").removesuffix(".a")

    linking_context, linking_outputs = cc_common.create_linking_context_from_compilation_outputs(
        actions = sctx.actions,
        name = archive_lib_name,
        feature_configuration = cc_feature_configuration_func(
            cc_toolchain,
            features = features,
            disabled_features = disabled_features,
        ),
        cc_toolchain = cc_toolchain,
        disallow_static_libraries = False,
        disallow_dynamic_library = True,
        compilation_outputs = compilation_outputs,
        linking_contexts = [
            dep[CcInfo].linking_context
            for dep in deps
            if CcInfo in dep
        ],
        user_link_flags = user_link_flags,
        alwayslink = False,
        # TODO: Is there a better way?
        additional_inputs = depset([], transitive = [i.files for i in additional_inputs]).to_list(),
        variables_extension = variables_extension,
    )

    return struct(
        linking_context = linking_context,
        linking_outputs = linking_outputs,
    )

link_to_archive = subrule(
    implementation = _link_to_archive_impl,
    attrs = {},
    toolchains = use_cc_toolchain(),
)
