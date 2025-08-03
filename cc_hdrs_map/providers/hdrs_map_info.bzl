""" Module describing HdrsMapInfo provider and common operations on it. """

load(
    "@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl",
    "new_hdrs_map",
)

HdrsMapInfo = provider(
    doc = "Represents grouping of CC header files, alongsdie with their intended include paths.",
    fields = {
        "hdrs": "Headers which should be exposed after the compilation is done.",
        "implementation_hdrs": "Headers that should not be propagated after the compilation.",
        "hdrs_map": "(hdrs_map struct) object describing desired header file mappings",
        "deps": "CcInfo/CcSharedLibraryInfo-aware dependencies that need to be propagated, for this provider to compile and link",
    },
)

def quotient_map_hdrs_map_infos(
        targets = [],
        hdrs = None,
        implementation_hdrs = None,
        hdrs_map = None,
        hdrs_map_deps = None):
    """ Take all HdrsMapInfo key-values and group them by keys.

    Args:
        hdrs: additional header files to include,
        implementation_hdrs: additional implementation headers to include,
        hdrs_map: initial hdrs_map to use as a foundation for merge,
        hdrs_map_deps: additional dependencies to include,

    Returns:
        (hdrs, implementation_hdrs, hdrs_map, hdr_maps_deps): tuple
    """

    # Sequences of Depsets
    hdrs = hdrs if hdrs else []
    implementation_hdrs = implementation_hdrs if implementation_hdrs else []
    hdrs_map = hdrs_map if hdrs_map else new_hdrs_map()
    hdr_map_deps = hdrs_map_deps if hdrs_map_deps else []

    for target in targets:
        if HdrsMapInfo not in target:
            # Skip HdrsMapInfo-unaware target
            continue

        if target[HdrsMapInfo].hdrs:
            hdrs.append(
                target[HdrsMapInfo].hdrs,
            )
        if target[HdrsMapInfo].implementation_hdrs:
            implementation_hdrs.append(
                target[HdrsMapInfo].implementation_hdrs,
            )
        if target[HdrsMapInfo].hdrs_map:
            hdrs_map = hdrs_map.merge(target[HdrsMapInfo].hdrs_map)
        if target[HdrsMapInfo].deps:
            hdr_map_deps.append(
                target[HdrsMapInfo].deps,
            )

    hdrs = depset(transitive = hdrs)
    implementation_hdrs = depset(transitive = implementation_hdrs)
    hdr_maps_deps = depset(transitive = hdr_map_deps)
    return hdrs, implementation_hdrs, hdrs_map, hdr_maps_deps

def merge_hdrs_map_infos(
        targets = [],
        hdrs = None,
        implementation_hdrs = None,
        hdrs_map = None,
        hdrs_map_deps = None,
        pin_down_non_globs = True):
    """ Merge all HdrsMapInfo providers from targets into singular one.

    Args:
        hdrs: additional header files to include,
        implementation_hdrs: additional implementation headers to include,
        hdrs_map: initial hdrs_map to use as a foundation for merge,
        hdrs_map_deps:  additional dependencies to include,
        pin_down_non_globs: wheather the final hdrs_map should have its
            non_glob dependencies pinned.

    Returns:
        HdrsMapInfo provider that represents merge of all HdrsMapInfos from targets.
    """
    hdrs, implementation_hdrs, hdrs_map, hdr_maps_deps = quotient_map_hdrs_map_infos(
        targets = targets,
        hdrs = hdrs,
        implementation_hdrs = implementation_hdrs,
        hdrs_map = hdrs_map,
        hdrs_map_deps = hdrs_map_deps,
    )

    if pin_down_non_globs:
        hdrs_map.pin_down_non_globs()

    return HdrsMapInfo(
        hdrs = hdrs,
        implementation_hdrs = implementation_hdrs,
        hdrs_map = hdrs_map,
        hdr_maps_deps = hdr_maps_deps,
    )
