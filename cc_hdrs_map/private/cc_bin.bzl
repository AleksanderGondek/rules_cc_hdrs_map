""" This module contains the implementation of cc_bin rule. """

load("@rules_cc_hdrs_map//cc_hdrs_map/actions:defs.bzl", "actions")
load("@rules_cc_hdrs_map//cc_hdrs_map/private:attrs.bzl", "get_cc_bin_attrs")

CC_BIN_ATTRS = get_cc_bin_attrs()

def _cc_bin_impl(ctx):
    _, compilation_outputs, _ = actions.compile(**actions.compile_kwargs(ctx, CC_BIN_ATTRS))

    linking_outputs = actions.link_to_binary(
        compilation_outputs,
        **actions.link_to_binary_kwargs(ctx, CC_BIN_ATTRS)
    )

    runfiles = []

    # TODO: Extract to separate module
    for data_dep in ctx.attr.data:
        if data_dep[DefaultInfo].data_runfiles.files:
            runfiles.append(data_dep[DefaultInfo].data_runfiles)
        else:
            # This branch ensures interop with custom Starlark rules following
            # https://bazel.build/extending/rules#runfiles_features_to_avoid
            runfiles.append(ctx.runfiles(transitive_files = data_dep[DefaultInfo].files))
            runfiles.append(data_dep[DefaultInfo].default_runfiles)

    return [
        DefaultInfo(
            executable = linking_outputs.executable,
            files = depset([linking_outputs.executable]),
            runfiles = ctx.runfiles(
                files = runfiles,
            ),
        ),
    ]

cc_bin = rule(
    implementation = _cc_bin_impl,
    attrs = {k: v.attr for k, v in CC_BIN_ATTRS.items()} | {
        "_use_auto_exec_groups": attr.bool(default = True),
    },
    doc = """Produce exectuable binary.

    It is intended for this rule, to differ from rules_cc's `cc_binary` in the following
    fashion: it aims to automatically gather all of its dynamic dependencies and make them
    available during binary execution.
    """,
    executable = True,
    fragments = ["cpp"],
    subrules = [actions.compile, actions.link_to_binary],
)
