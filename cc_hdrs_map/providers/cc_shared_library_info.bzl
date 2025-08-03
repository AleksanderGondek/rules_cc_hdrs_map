"""This module contains function that help with dealing with CcSharedLibraryInfo provider."""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("@rules_cc//cc/common:cc_shared_library_info.bzl", "CcSharedLibraryInfo")

def quotient_map_cc_shared_library_infos(
        targets = [],
        dynamic_deps = None,
        exports = None,
        linker_input = None,
        link_once_static_libs = None):
    """ Transform list of Bazel targets into CcSharedLibrayInfo attribue groups.

    For given list of Bazel targets, attributes relating to CcSharedLibraryInfo
    (dynamic_deps, exports, linker_inputs, link_once_static_libs) will be extracted
    from said targets and the output will contain groups of that values.

    Args:
        targets: list of Bazel targets that should be mapped. They must
          contain either CcInfo or CcSharedLibraryInfo provider.
        dynamic_deps: sequence of Depsets representing additional dynamic deps.
        exports: cc_libraries that are linked statically and exported".
        linker_input: the resultign linker inptu artifact for the shared library.
        link_once_static_libs: all libraries linked statically into this library that should
          only be linked once.

    Returns:
        (dynamic_deps, exports, linker_inptuts, link_once_static_lib)
    """

    # Sequence of Depsets
    dynamic_deps = dynamic_deps if dynamic_deps else []

    # Label to Bool mapping
    exports = exports if exports else {}
    link_once_static_libs = link_once_static_libs if link_once_static_libs else []

    direct_dynamic_deps = []
    transitive_dynamic_deps = []
    for target in targets:
        if CcInfo in target:
            # TODO: This is quite naive approach
            exports[str(target.label)] = True
        if not CcSharedLibraryInfo in target:
            continue

        dynamic_dep_entry = struct(
            exports = target[CcSharedLibraryInfo].exports,
            linker_input = target[CcSharedLibraryInfo].linker_input,
            link_once_static_libs = target[CcSharedLibraryInfo].link_once_static_libs,
        )
        direct_dynamic_deps.append(dynamic_dep_entry)
        transitive_dynamic_deps.append(target[CcSharedLibraryInfo].dynamic_deps)

    dynamic_deps = depset(direct = direct_dynamic_deps, transitive = dynamic_deps + transitive_dynamic_deps, order = "topological")
    return (
        dynamic_deps,
        exports,
        linker_input,
        link_once_static_libs,
    )

def merge_cc_shared_library_infos(
        targets = [],
        dynamic_deps = None,
        exports = None,
        linker_input = None,
        link_once_static_libs = None):
    """ Merge CcSharedLibraryInfos from targets into singualr provider.

    Args:
        targets: list of Bazel targets that should be merged. They must
          contain either CcInfo or CcSharedLibraryInfo provider.
        dynamic_deps: sequence of Depsets representing additional dynamic deps.
        exports: cc_libraries that are linked statically and exported".
        linker_input: the resultign linker inptu artifact for the shared library.
        link_once_static_libs: all libraries linked statically into this library that should
          only be linked once.

    Returns:
        CcSharedLibraryInfo provider.
    """
    dynamic_deps, exports, linker_input, link_once_static_libs = quotient_map_cc_shared_library_infos(
        targets = targets,
        dynamic_deps = dynamic_deps,
        exports = exports,
        linker_input = linker_input,
        link_once_static_libs = link_once_static_libs,
    )

    return CcSharedLibraryInfo(
        dynamic_deps = dynamic_deps,
        exports = exports,
        linker_input = linker_input,
        link_once_static_libs = link_once_static_libs,
    )
