""" Module describing HdrsMapInfo provider and common operations on it. """

load(
    "@rules_cc_hdrs_map//cc_hdrs_map/actions:copy_file.bzl",
    "copy_file",
)
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
        "deps": "CcInfo-aware dependencies that need to be propagated, for this provider to compile and link",
    },
)

def glob_match(
        pattern,
        text):
    """ Check if given path matches the simple glob expression.

    Supported special characters:
    `*` Will match zero or more characters, until it hits '/'
    `?` Will match exactly one character of any kind, except for '/'
    `<expr>/**` Will match anything after '<expr>/'
    `**/<expr>` Will match greedily until it hits /<expr> (otherwise it
        will not be considered a match)
    `<expr>**<expr>` just as '*`

    This implementation is a clusterfuck, yet I hardly see
    any room to improve it in starlark.

    Args:
        pattern: glob expression to match
        text: the path against which we are matching the pattern

    Returns:
        Boolean: indicating if text matches the pattern
    """

    # pi stands for pattern index
    # p represents single charactern from the pattern
    pi = 0
    p = pattern[pi] if pattern else None

    # ti stands for text index
    # t represents single character from the text
    ti = 0
    t = text[ti] if text else None

    # Authors' soap box:
    # 1) Starklark is god-fosaken language
    #    while loop is not allowed, so instead
    #    of 'while t' we get this...
    # 2) Buildifier formats comments that should
    #    describe elifs as part of pervious if..
    for _ in range(1073741824):
        # Equivalent to 'while t':
        # if selected t is non None
        # append element to list, to ensure
        # continous iteration.
        if not t:
            break

        next_p = pattern[pi + 1] if pi + 1 < len(pattern) else None
        next_t = text[ti + 1] if ti + 1 < len(text) else None

        # '*' followed by nothing
        #   => match greedily until text exhaustion
        if p == "*" and not next_p:
            ti = ti + 1
            t = text[ti] if ti < len(text) else None

        # '**' special wildcard
        if p == "*" and next_p == "*":
            pi = pi + 2
            p = pattern[pi] if pi < len(pattern) else None

            # '**' was the end of the pattern
            #   => therfore it matches anything left!
            if not p:
                return True

            # '**/{expr}'
            #   => therefore we check if text contains expected expr
            #      note: we just search for / plus singular pattern char
            if p == "/":
                x = pattern[pi + 1] if pi + 1 < len(pattern) else None
                if x == "*" or x == "?":
                    # Star or question mark means next '/' is the hit
                    jump_point = text.find("/", ti)
                else:
                    # Match precisely place in the expression
                    jump_point = text.find("/" + x, ti)

                if jump_point < 0:
                    return False

                ti = jump_point
                t = text[ti] if ti < len(text) else None
                # **<something>
                #   => just jump matching position to last star

            else:
                pi = pi - 1  # rollback to last star
                p = pattern[pi] if pi < len(pattern) else None
                ti = ti + 1
                t = text[ti] if ti < len(text) else None

            # '*' not followed by '/'
            #   => Match the current character

        elif p == "*" and next_t != "/":
            ti = ti + 1
            t = text[ti] if ti < len(text) else None

            # Ensure *<something> is covered
            #   => next_p matches the character excactly
            if next_p == t:
                pi = pi + 1
                p = pattern[pi] if pi < len(pattern) else None

            # '*' followed by '/'
            #   => Stop star matching

        elif p == "*" and next_t == "/":
            ti = ti + 1
            t = text[ti] if ti < len(text) else None
            pi = pi + 1
            p = pattern[pi] if pi < len(pattern) else None

            # '?' and character is not '/'
            #   => Progress matching

        elif p == "?" and t != "/":
            ti = ti + 1
            t = text[ti] if ti < len(text) else None
            pi = pi + 1
            p = pattern[pi] if pi < len(pattern) else None

            # 1:1 match
            #   => Progress matching

        elif p == t:
            ti = ti + 1
            t = text[ti] if ti < len(text) else None
            pi = pi + 1
            p = pattern[pi] if pi < len(pattern) else None

        elif p != t and ti < len(text) and pi > 0:
            # Partial match with more text to follow
            pi = 0
            p = pattern[pi]
            # Everything else is a non-match

        else:
            return False

    # Cleanup
    # Starklark is god-fosaken language
    # while loop is not allowed, so instead
    # of 'while p == "*"' we get this..
    for _ in range(pi, len(pattern)):
        if p != "*":
            break

        pi = pi + 1
        p = pattern[pi] if pi < len(pattern) else None

    # At this point, pattern should be exhausted
    # if it isn't, it means it was not matched
    return p == None

def _materialize_hdr_mapping(ctx_actions, parent_dir_name, source_hdr_file, mappings):
    mapped_files = []
    for mapping in mappings:
        # Ensure {filename} is translated to header_file name
        target = mapping.replace("{filename}", source_hdr_file.basename)

        # TODO: Hash the label name and add as prefix?
        mapping_path = "/".join([
            parent_dir_name,
            target,
        ])
        mapping_file = ctx_actions.declare_file(
            mapping_path,
        )
        copy_file(
            ctx_actions = ctx_actions,
            src = source_hdr_file,
            dst = mapping_file,
        )
        mapped_files.append(mapping_file)

    return mapped_files

def materialize_hdrs_mapping(
        invoker_label,
        actions,
        hdrs_map,
        hdrs):
    """ Materialize the expected file hierarchy.

    Creates the header file hierarchy accordingly to specifications
    in passed-in hdrs_map under 'vhm' directory.

    Args:
        invoker_label: label of rule invoking the method
        actions: bazel ctx.actions
        hdrs_map: HdrsMapInfo representing the headers mapping
        hdrs: list of all header files that should be matched against the map

    Returns:
        (materialized_include_path, materialized_hdrs_files): tuple of include_path to
        the created header files dir and list of paths to all header files created.
    """
    HEADERS_MAP_DIR_NAME = invoker_label.name + ".vhm"
    materialized_include_path = None
    materialized_hdrs_files = []

    for header_file in hdrs.to_list():
        if ".vhm" in header_file.path:
            # This is important! Improve the check
            continue
        if header_file.path in hdrs_map.non_glob:
            # This is happening before globbing to improve perf.
            materialized_hdrs_files.extend(
                _materialize_hdr_mapping(
                    actions,
                    HEADERS_MAP_DIR_NAME,
                    header_file,
                    hdrs_map.non_glob.get(header_file.path),
                ),
            )
            continue

        for pattern, mappings in hdrs_map.glob.items():
            if not glob_match(pattern, header_file.path):
                continue
            materialized_hdrs_files.extend(
                _materialize_hdr_mapping(
                    actions,
                    HEADERS_MAP_DIR_NAME,
                    header_file,
                    mappings,
                ),
            )

    if materialized_hdrs_files:
        hdr = materialized_hdrs_files[0]
        materialized_include_path = "/".join([
            hdr.path.rsplit(HEADERS_MAP_DIR_NAME)[0],
            HEADERS_MAP_DIR_NAME,
        ])

    return materialized_include_path, materialized_hdrs_files

def merge_hdrs_maps_info_from_deps(
        deps,
        hdrs_map):
    """ Aggregate any HdrsMapInfo from the dependencies.

    Merges all HdrsMapInfos from the dependencies of a bazel target into
    a singular description of mappings that exists.

    Args:
        deps: list of dependencies of the Bazel target
        hdrs_map: map of headers of the Bazel target

    Returns:
        (hdrs, implementation_hdrs, hdrs_map, hdr_maps_deps): tuple
        containing list of public headers, private headers, merged hdrs_map and other dependencies.
    """

    # Sequence of Depset
    hdrs = []
    implementation_hdrs = []
    hdrs_map = hdrs_map if hdrs_map else new_hdrs_map()
    hdr_maps_deps = []

    for dependency in deps:
        if HdrsMapInfo not in dependency:
            # Merge hdrs only for HdrsMapInfo-aware deps
            continue

        if dependency[HdrsMapInfo].hdrs:
            hdrs.append(
                dependency[HdrsMapInfo].hdrs,
            )
        if dependency[HdrsMapInfo].implementation_hdrs:
            implementation_hdrs.append(
                dependency[HdrsMapInfo].implementation_hdrs,
            )
        if dependency[HdrsMapInfo].hdrs_map:
            hdrs_map = hdrs_map.merge(dependency[HdrsMapInfo].hdrs_map)
        if dependency[HdrsMapInfo].deps:
            hdr_maps_deps.append(
                dependency[HdrsMapInfo].deps,
            )

    hdrs = depset(transitive = hdrs)
    implementation_hdrs = depset(transitive = implementation_hdrs)
    hdr_maps_deps = depset(transitive = hdr_maps_deps)
    return hdrs, implementation_hdrs, hdrs_map, hdr_maps_deps
