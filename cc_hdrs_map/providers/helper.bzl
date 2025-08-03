""" This module exposes the common operatiosn done towards providers as a helper struct. """

load("@rules_cc_hdrs_map//cc_hdrs_map/providers:cc_shared_library_info.bzl", _merge_cc_shared_library_infos = "merge_cc_shared_library_infos", _quotient_map_cc_shared_library_infos = "quotient_map_cc_shared_library_infos")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl", _materialize_hdrs_mapping = "materialize_hdrs_mapping", _new_hdrs_map = "new_hdrs_map")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map_info.bzl", _merge_hdrs_map_infos = "merge_hdrs_map_infos", _quotient_map_hdrs_map_infos = "quotient_map_hdrs_map_infos")

providers_helper = struct(
    # Providers
    merge_cc_shared_library_infos = _merge_cc_shared_library_infos,
    quotient_map_cc_shared_library_infos = _quotient_map_cc_shared_library_infos,
    merge_hdrs_map_infos = _merge_hdrs_map_infos,
    quotient_map_hdrs_map_infos = _quotient_map_hdrs_map_infos,
    # HdrsMap which is subobject of HdrsMapInfo
    new_hdrs_map = _new_hdrs_map,
    materialize_hdrs_mapping = _materialize_hdrs_mapping,
)
