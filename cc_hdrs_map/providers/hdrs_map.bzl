""" Module describing HdrsMap struct and common operations on it. """

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
