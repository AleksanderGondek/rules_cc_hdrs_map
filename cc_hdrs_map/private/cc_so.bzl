""" This module contains the implementation of the cc_so rule. """

load("@rules_cc//cc/common:cc_shared_library_info.bzl", "CcSharedLibraryInfo")
load("@rules_cc_hdrs_map//cc_hdrs_map/actions:defs.bzl", "actions")
load("@rules_cc_hdrs_map//cc_hdrs_map/private:attrs.bzl", "get_cc_so_attrs")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl", "HdrsMapInfo")

CC_SO_ATTRS = get_cc_so_attrs()

def _cc_so_impl(ctx):
    _, compilation_outputs, hdrs_map_ctx = actions.compile(**actions.compile_kwargs(ctx, CC_SO_ATTRS))
    shared_cc, linking_outputs = actions.link_to_so(
        compilation_outputs,
        **actions.link_to_so_kwargs(ctx, CC_SO_ATTRS)
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

    output_files = []
    if linking_outputs.library_to_link.resolved_symlink_dynamic_library:
        runfiles.append(linking_outputs.library_to_link.resolved_symlink_dynamic_library)
        output_files.append(linking_outputs.library_to_link.resolved_symlink_dynamic_library)

    if linking_outputs.library_to_link.dynamic_library:
        runfiles.append(linking_outputs.library_to_link.dynamic_library)
        output_files.append(linking_outputs.library_to_link.dynamic_library)

    return [
        DefaultInfo(
            files = depset(output_files),
            runfiles = ctx.runfiles(
                files = runfiles,
            ),
        ),
        CcSharedLibraryInfo(
            dynamic_deps = shared_cc.dynamic_deps,
            exports = shared_cc.exports,
            link_once_static_libs = shared_cc.link_once_static_libs,
            linker_input = shared_cc.linker_input,
        ),
        HdrsMapInfo(
            hdrs = depset(hdrs_map_ctx.hdrs),
            # Implementation hdrs do not leave the scope of this lib
            implementation_hdrs = depset([]),
            hdrs_map = hdrs_map_ctx.hdrs_map,
            deps = depset([
                d
                for d in hdrs_map_ctx.deps
            ]),
        ),
    ]

cc_so = rule(
    implementation = _cc_so_impl,
    attrs = {k: v.attr for k, v in CC_SO_ATTRS.items()} | {
        "_use_auto_exec_groups": attr.bool(default = True),
    },
    doc = """Produce shared object library.

    The intended difference between this rule and the rules_cc's cc_shared_library is to:
     1) remove 'cc_library' out of the equation (no more targets that produce either archive or sol)
     2) unify handling of dependencies that are equipped with CcInfo and CcSharedLibraryInfo
        (use singular attribute of deps to track them both).
    """,
    fragments = ["cpp"],
    provides = [DefaultInfo, CcSharedLibraryInfo, HdrsMapInfo],
    subrules = [actions.compile, actions.link_to_so],
)
