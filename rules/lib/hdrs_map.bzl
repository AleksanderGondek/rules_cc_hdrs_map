""" Module describing HdrsMapInfo provider and common operations on it. """

load(
    "@rules_cc_hdrs_map//rules:lib/copy_file.bzl",
    "copy_file",
)

HdrsMapInfo = provider(
    doc = "",
    fields = {
        "public_hdrs": "To be described",
        "private_hdrs": "To be described",
        "hdrs_map": "To be described, string_list_dict",
        "deps": "To be described",
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

def materialize_hdrs_mapping(
        invoker_label,
        actions,
        is_windows,
        hdrs_map,
        hdrs):
    """ Materialize the expected file hierarchy.

    Creates the header file hierarchy accordingly to specifications
    in passed-in hdrs_map under 'vhm' directory.

    Args:
        invoker_label: label of rule invoking the method
        actions: bazel ctx.actions
        is_windows: steers execution of windows/unix copying mechanism.
        hdrs_map: HdrsMapInfo representing the headers mapping
        hdrs: list of all header files that should be matched against the map

    Returns:
        (materialized_include_path, materialized_hdrs_files): tuple of include_path to
        the created header files dir and list of paths to all header files created.
    """
    HEADERS_MAP_DIR_NAME = "vhm"
    materialized_include_path = None
    materialized_hdrs_files = []

    for pattern, mappings in hdrs_map.items():
        for header_file in hdrs:
            if not glob_match(pattern, header_file.path):
                continue

            for mapping in mappings:
                # Ensure {filename} is translated to header_file name
                target = mapping.replace("{filename}", header_file.basename)

                # TODO: Hash the label name and add as prefix?
                mapping_path = "/".join([
                    HEADERS_MAP_DIR_NAME,
                    target,
                ])
                mapping_file = actions.declare_file(
                    mapping_path,
                )
                copy_file(
                    invoker_label = invoker_label,
                    actions = actions,
                    is_windows = is_windows,
                    src = header_file,
                    dst = mapping_file,
                )
                materialized_hdrs_files.append(mapping_file)

    if materialized_hdrs_files:
        hdr = materialized_hdrs_files[0]
        materialized_include_path = "/".join([
            hdr.path.rsplit(HEADERS_MAP_DIR_NAME)[0],
            HEADERS_MAP_DIR_NAME,
        ])

    return materialized_include_path, materialized_hdrs_files

def merge_hdrs_map(
        hdr_maps_one,
        hdr_maps_two):
    """ Merge two HdrsMapInfo hdrs_maps together.

    Args:
        hdr_maps_one: first HdrsMapInfo to be merged
        hdr_maps_two: second HdrsMapInfo to be merged

    Returns:
        Dict: merged together hdrs_maps
    """
    final_mappings = {}
    for pattern, mappings in hdr_maps_one.items():
        if pattern not in final_mappings:
            final_mappings[pattern] = []

        for mapping in mappings:
            if mapping in final_mappings[pattern]:
                continue

            final_mappings[pattern].append(mapping)

    for pattern, mappings in hdr_maps_two.items():
        if pattern not in final_mappings:
            final_mappings[pattern] = []

        for mapping in mappings:
            if mapping in final_mappings[pattern]:
                continue

            final_mappings[pattern].append(mapping)

    return final_mappings

def merge_hdr_maps_info_from_deps(
        deps,
        hdrs_map):
    """ Aggregate any HdrsMapInfo from the dependencies.

    Merges all HdrsMapInfos from the dependencies of a bazel target into
    a singular description of mappings that exists.

    Args:
        deps: list of dependencies of the Bazel target
        hdrs_map: map of headers of the Bazel target

    Returns:
        (public_hdrs, private_hdrs, hdrs_map, hdr_maps_deps): tuple
        containing list of public headers, private headers, merged hdrs_map and other dependencies.
    """
    public_hdrs = []
    private_hdrs = []
    hdrs_map = hdrs_map if hdrs_map else {}
    hdr_maps_deps = []

    for dependency in deps:
        if HdrsMapInfo not in dependency:
            # Merge hdrs only for HdrsMapInfo-aware deps
            continue

        if dependency[HdrsMapInfo].public_hdrs:
            public_hdrs.extend(
                dependency[HdrsMapInfo].public_hdrs.to_list(),
            )
        if dependency[HdrsMapInfo].private_hdrs:
            private_hdrs.extend(
                dependency[HdrsMapInfo].private_hdrs.to_list(),
            )
        if dependency[HdrsMapInfo].hdrs_map:
            hdrs_map = merge_hdrs_map(
                hdrs_map,
                dependency[HdrsMapInfo].hdrs_map,
            )
        if dependency[HdrsMapInfo].deps:
            hdr_maps_deps.extend(
                dependency[HdrsMapInfo].deps.to_list(),
            )

    return public_hdrs, private_hdrs, hdrs_map, hdr_maps_deps
