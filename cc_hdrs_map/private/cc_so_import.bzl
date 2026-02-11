""" This module contains the implementation of the cc_so_import rule. """

load("@rules_cc//cc:defs.bzl", "cc_common")
load(
    "@rules_cc//cc:find_cc_toolchain.bzl",
    "find_cc_toolchain",
    "use_cc_toolchain",
)
load("@rules_cc//cc/common:cc_shared_library_info.bzl", "CcSharedLibraryInfo")
load("@rules_cc_hdrs_map//cc_hdrs_map/actions:defs.bzl", "actions")
load("@rules_cc_hdrs_map//cc_hdrs_map/private:attrs.bzl", "get_cc_so_import_attrs")
load("@rules_cc_hdrs_map//cc_hdrs_map/private:common.bzl", "prepare_default_runfiles")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:cascading_cc_shared_library_info.bzl", "CascadingCcSharedLibraryInfo")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:cc_shared_library_info.bzl", "merge_cc_shared_library_infos")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl", "new_hdrs_map")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map_info.bzl", "HdrsMapInfo", "quotient_map_hdrs_map_infos")

CC_SO_IMPORT_ATTRS = get_cc_so_import_attrs()

# TODO: Whole implementation requires a touch-up
def _cc_so_import_impl(ctx):
    hdrs = [h for h in ctx.files.hdrs]
    deps = [d for d in ctx.attr.deps] + [dd for dd in ctx.attr.dynamic_deps]
    hdrs_map = new_hdrs_map(from_dict = ctx.attr.hdrs_map if ctx.attr.hdrs_map else {})

    # TODO: Another place to refactor
    strip_include_prefix = ctx.attr.strip_include_prefix
    include_prefix = ctx.attr.include_prefix
    if strip_include_prefix or include_prefix:
        for hdr in hdrs:
            basename = hdr.basename
            path = hdr.path
            mappings = hdrs_map.non_glob.setdefault(path, [])
            if strip_include_prefix:
                path = path.removeprefix("{}/".format(strip_include_prefix))
            if include_prefix:
                path = "/".join(path.split("/{}".format(basename))[:-1] + [include_prefix, basename])
            mappings.append(path)

    # Pattern of '{filename}' resolves to any direct header file of the rule instance
    hdrs_map.pin_down_non_globs(hdrs = hdrs)

    deps_pub_hdrs, _, hdrs_map, deps_deps = quotient_map_hdrs_map_infos(
        targets = deps,
        hdrs = None,
        implementation_hdrs = None,
        hdrs_map = hdrs_map,
        hdrs_map_deps = None,
        # DO NOT pay the transitive traversal cost upfront
        traverse_deps = False,
    )

    hdrs = depset(direct = hdrs, transitive = [deps_pub_hdrs])
    deps = depset(direct = deps, transitive = [deps_deps])

    linker_input = cc_common.create_linker_input(
        owner = ctx.label,
        # TODO: This logic needs unification with other pleaces
        libraries = depset([
            cc_common.create_library_to_link(
                actions = ctx.actions,
                feature_configuration = cc_common.configure_features(
                    ctx = ctx,
                    cc_toolchain = find_cc_toolchain(ctx),
                    requested_features = ctx.features + ["force_no_whole_archive"],
                    unsupported_features = ctx.disabled_features,
                ),
                cc_toolchain = find_cc_toolchain(ctx),
                dynamic_library = ctx.file.shared_library,
            ),
        ]),
        additional_inputs = depset([i for i in ctx.files.additional_linker_inputs]),
        # TODO: Expansion of 'make variables'
        # (This requires a bit of restructuring of how attributes are handled)
        user_link_flags = ctx.attr.linkopts,
    )
    cc_shared_library_info = merge_cc_shared_library_infos(
        targets = deps.to_list(),
        exports = {str(ctx.label): True},
        linker_input = linker_input,
    )
    providers = [
        DefaultInfo(
            files = depset(
                [ctx.file.shared_library],
                transitive = [
                    hdrs,
                ],
            ),
            runfiles = prepare_default_runfiles(
                ctx.runfiles,
                ctx.attr.data,
                ctx.attr.deps,
                files = ctx.files.data,
            ),
        ),
        cc_shared_library_info,
        HdrsMapInfo(
            hdrs = hdrs,
            implementation_hdrs = [],
            hdrs_map = hdrs_map,
            deps = deps,
        ),
    ]

    if ctx.attr.cascade:
        providers.append(CascadingCcSharedLibraryInfo(cc_shared_library_infos = [cc_shared_library_info]))

    return providers

cc_so_import = rule(
    implementation = _cc_so_import_impl,
    attrs = {k: v.attr for k, v in CC_SO_IMPORT_ATTRS.items()} | {
        "_use_auto_exec_groups": attr.bool(default = True),
    },
    doc = """Import precompiled C/C++ shared object library.

    The intended difference between this rule and the rules_cc's cc_import is to directly
    provide CcSharedLibrary info to force linking and early deps cutoff.
    """,
    fragments = ["cpp"],
    provides = [DefaultInfo, CcSharedLibraryInfo, HdrsMapInfo],
    subrules = [],
    toolchains = use_cc_toolchain(),
)
