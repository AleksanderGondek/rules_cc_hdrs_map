""" Contains common configuration-related entities used by cc_hdrs_map rules. """

_COMMON_RULES_ATTRS = {
    "deps": attr.label_list(
        doc = "",
        default = [],
    ),
    "srcs": attr.label_list(
        mandatory = True,
        allow_files = [
            ".c",
            ".cc",
            ".cpp",
            ".cxx",
            ".c++",
            ".C",
        ],
        doc = "",
    ),
    "public_hdrs": attr.label_list(
        allow_files = [
            ".h",
            ".hh",
            ".hpp",
            ".hxx",
            ".inc",
            ".inl",
            ".H",
        ],
        doc = "",
        default = [],
    ),
    "private_hdrs": attr.label_list(
        allow_files = [
            ".h",
            ".hh",
            ".hpp",
            ".hxx",
            ".inc",
            ".inl",
            ".H",
        ],
        doc = "",
        default = [],
    ),
    "hdrs_map": attr.string_list_dict(
        doc = "",
        default = {},
    ),
}

_CC_COMPILABLE_ATTRS = {
    "additional_linker_inputs": attr.label_list(
        doc = "",
        default = [],
    ),
    "copts": attr.string_list(
        doc = "",
        default = [],
    ),
    "defines": attr.string_list(
        doc = "",
        default = [],
    ),
    "includes": attr.string_list(
        doc = "",
        default = [],
    ),
    "linkopts": attr.string_list(
        doc = "",
        default = [],
    ),
    "linkstatic": attr.bool(
        default = True,
        doc = "",
    ),
    "local_defines": attr.string_list(
        doc = "",
        default = [],
    ),
    "_cc_toolchain": attr.label(
        default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
    ),
    "_is_windows": attr.bool(
        default = False,
        doc = "",
    ),
}

_CC_LIB_ATTRS = {
    "include_prefix": attr.string(
        doc = "",
        default = "",
    ),
    "strip_include_prefix": attr.string(
        doc = "",
        default = "",
    ),
}

# Authors' soap box:
# + no longer works, neither does |
#  "{**dictA, **dictB}" never did..
#   update modifies in place..

def get_cc_bin_attrs():
    """ To be described """
    cc_bin_attrs = {
        "stamp": attr.int(
            default = -1,
            doc = "",
        ),
    }
    cc_bin_attrs.update(_COMMON_RULES_ATTRS)
    cc_bin_attrs.update(_CC_COMPILABLE_ATTRS)
    return cc_bin_attrs

def get_cc_hdrs_attrs():
    """ To be described. """
    cc_hdrs_attrs = {}
    cc_hdrs_attrs.update(_COMMON_RULES_ATTRS)
    cc_hdrs_attrs.pop("srcs")
    return cc_hdrs_attrs

def get_cc_so_attrs():
    """ To be described. """
    cc_so_attrs = {
        "alwayslink": attr.bool(
            default = True,
            doc = "",
        ),
    }
    cc_so_attrs.update(_COMMON_RULES_ATTRS)
    cc_so_attrs.update(_CC_COMPILABLE_ATTRS)
    cc_so_attrs.update(_CC_LIB_ATTRS)
    return cc_so_attrs

def get_cc_static_attrs():
    """ To be described. """
    cc_static_attrs = {}
    cc_static_attrs.update(_COMMON_RULES_ATTRS)
    cc_static_attrs.update(_CC_COMPILABLE_ATTRS)
    cc_static_attrs.update(_CC_LIB_ATTRS)
    return cc_static_attrs
