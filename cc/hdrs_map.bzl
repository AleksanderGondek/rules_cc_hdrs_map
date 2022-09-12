""" To be described. """

load(
    "@rules_cc_hdrs_map//cc:conf.bzl",
    "CC_COMPILABLE_ATTRS",
    "CC_LIB_ATTRS",
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

# In future (Bazel >5), one can specify init function for providers..
# Therefore this method is using certain scheme.
# 
# It's possible to define an init accepting positional arguments, but
# keyword-only arguments are preferred.
# https://docs.bazel.build/versions/main/skylark/rules.html#custom-initialization-of-providers
def new_hdrs_map_info(
    public_hdrs = None,
    private_hdrs = None,
    hdrs_map = None,
    deps = None,
):
    """ To be described. """
    return HdrsMapInfo(
        public_hdrs = public_hdrs,
        private_hdrs = private_hdrs,
        hdrs_map = hdrs_map,
        deps = deps
    )

def _new_hdr_map_info_cc_compilable_attrs():
    """ To be descibed. """
    return {
        k: None for k in CC_COMPILABLE_ATTRS.keys()
    }

def _new_hdr_map_info_cc_lib_attrs():
    """ To be descibed. """
    return {
        k: None for k in CC_LIB_ATTRS.keys()
    }

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

    # Starklark is god-fosaken language
    # while loop is not allowed, so instead
    # of 'while t' we get this...
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
        actions,
        hdrs_map,
        hdrs):
    """ To be described. """
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
                actions.run_shell(
                    outputs = [mapping_file],
                    inputs = [header_file],
                    # This adds '' before cp command, causing it to fail...
                    # arguments = [
                    #     header_file.path,
                    #     mapping_file.path
                    # ],
                    command = "cp {} {}".format(header_file.path, mapping_file.path),
                    progress_message = "Materializing public hdr mapping from '%{input}' to '%{output}'",
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
    """ To be described. """
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
    """To be described. """
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
