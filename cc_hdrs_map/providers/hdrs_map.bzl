""" Module describing HdrsMap struct and common operations on it. """

load(
    "@rules_cc_hdrs_map//cc_hdrs_map/actions:copy_file.bzl",
    "copy_file",
)

def _hdrs_map_init(self, from_dict = {}):
    for pattern, targets in from_dict.items():
        selected_targets = None
        if "{filename}" == pattern:
            selected_targets = self.non_glob.setdefault(pattern, [])
        else:
            selected_targets = self.glob.setdefault(pattern, [])

        for target in targets:
            if target in selected_targets:
                continue
            selected_targets.append(target)

def _hdrs_map_merge_dicts(
        hdr_maps_one,
        hdr_maps_two):
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

def _hdrs_map_merge(self, other):
    return new_hdrs_map(
        _glob = _hdrs_map_merge_dicts(self.glob, other.glob),
        _non_glob = _hdrs_map_merge_dicts(self.non_glob, other.non_glob),
    )

def _hdrs_map_pin_down_non_globs(self, hdrs = []):
    all_non_glob_patterns = self.non_glob.keys()
    for pat in all_non_glob_patterns:
        if pat != "{filename}":
            continue

        mappings = self.non_glob.pop(pat, [])
        for hdr in hdrs:
            self.non_glob.setdefault(hdr.path, []).extend(mappings)

def new_hdrs_map(from_dict = {}, _glob = None, _non_glob = None):
    """Create new instance of HdrsMap struct."""
    self = struct(
        glob = _glob if _glob else {},
        non_glob = _non_glob if _non_glob else {},
        init = lambda fd: _hdrs_map_init(self, fd),
        merge = lambda other: _hdrs_map_merge(self, other),
        pin_down_non_globs = lambda hdrs: _hdrs_map_pin_down_non_globs(self, hdrs),
    )
    self.init(from_dict)
    return self

def _glob_match(
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

def _materialize_hdr_mapping(ctx_actions, parent_dir_name, source_hdr_file, mappings, existing_paths = None):
    existing_paths = existing_paths if existing_paths else set()
    mapped_files = []

    for mapping in mappings:
        # Ensure {filename} is translated to header_file name
        target = mapping.replace("{filename}", source_hdr_file.basename)

        # TODO: Made this behavior configurable
        # It might be the case, that aggregation of different header mapping, will result
        # in two or more files attempting to create given mapping.
        # For now - we are implementing "first-write-wins" strategy, where
        # every subsequent attempt results in warnings.
        if target in existing_paths:
            print("[WARN][rules_cc_hdrs_map] {} attempts to overwrite mapping of {}. Refusing and continuing.".format(source_hdr_file.path, target))
            continue

        existing_paths.add(target)

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

    return mapped_files, existing_paths

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

    # Retain paths (relative to HEADERS_MAP_DIR_NAME)
    # of all header files that were created during mapping phase.
    # This bookeeping is used for detection of scenario,
    # that would lead to attempt to create a duplicated file,
    # and would result in Bazel error.
    materialized_hdrs_paths_rel = set()

    # TODO: Refactor this nested-loop logic
    for header_file in hdrs.to_list():
        if ".vhm" in header_file.path:
            # This is important! Improve the check
            continue
        if header_file.path in hdrs_map.non_glob:
            # This is happening before globbing to improve perf.
            created_hdrs, created_hdrs_paths_rel = _materialize_hdr_mapping(
                actions,
                HEADERS_MAP_DIR_NAME,
                header_file,
                hdrs_map.non_glob.get(header_file.path),
                materialized_hdrs_paths_rel,
            )
            materialized_hdrs_files.extend(created_hdrs)
            materialized_hdrs_paths_rel.update(created_hdrs_paths_rel)
            continue

        for pattern, mappings in hdrs_map.glob.items():
            if not _glob_match(pattern, header_file.path):
                continue
            created_hdrs, created_hdrs_paths_rel = _materialize_hdr_mapping(
                actions,
                HEADERS_MAP_DIR_NAME,
                header_file,
                mappings,
                materialized_hdrs_paths_rel,
            )
            materialized_hdrs_files.extend(created_hdrs)
            materialized_hdrs_paths_rel.update(created_hdrs_paths_rel)

    if materialized_hdrs_files:
        hdr = materialized_hdrs_files[0]
        materialized_include_path = "/".join([
            hdr.path.rsplit(HEADERS_MAP_DIR_NAME)[0],
            HEADERS_MAP_DIR_NAME,
        ])

    return materialized_include_path, materialized_hdrs_files
