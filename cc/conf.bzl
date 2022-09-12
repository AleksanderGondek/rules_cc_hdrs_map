""" Contains common configuration-related entities used by cc_hdrs_map rules. """

_COMMON_RULES_ATTRS = {
    "deps": attr.label_list(
        doc = "",
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
    ),
    "hdrs_map": attr.string_list_dict(
        doc = "",
    ),
}

_CC_COMPILABLE_ATTRS = {
    "additional_linker_inputs": attr.label_list(
        doc = "",
    ),
    "copts": attr.string_list(
        doc = "",
    ),
    "defines": attr.string_list(
        doc = "",
    ),
    "includes": attr.string_list(
        doc = "",
    ),
    "linkopts": attr.string_list(
        doc = "",
    ),
    "linkstatic": attr.bool(
        default = True,
        doc = "",
    ),
    "local_defines": attr.string_list(
        doc = "",
    ),
    "_cc_toolchain": attr.label(
        default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
    ),
}

_CC_LIB_ATTRS = {
    "includes_prefix": attr.string(
        doc = "",
    ),
    "strip_include_prefix": attr.string(
        doc = "",
    ),
}

# Authors' soap box: + no longer works, neither does |
#  "{**dictA, **dictB}" never did..
#   update modifies in place..

CC_BIN_ATTRS = {
    "stamp": attr.int(
        default = -1,
        doc = "",
    ),
}
CC_BIN_ATTRS.update(_COMMON_RULES_ATTRS)
CC_BIN_ATTRS.update(_CC_COMPILABLE_ATTRS)

CC_SO_ATTRS = {
    "alwayslink": attr.bool(
        default = True,
        doc = "",
    ),
}
CC_SO_ATTRS.update(_COMMON_RULES_ATTRS)
CC_SO_ATTRS.update(_CC_COMPILABLE_ATTRS)
CC_SO_ATTRS.update(_CC_LIB_ATTRS)

CC_STATIC_ATTRS = {}
CC_STATIC_ATTRS.update(_COMMON_RULES_ATTRS)
CC_STATIC_ATTRS.update(_CC_COMPILABLE_ATTRS)
CC_STATIC_ATTRS.update(_CC_LIB_ATTRS)

CC_HDRS_ATTRS = {}
CC_HDRS_ATTRS.update(_COMMON_RULES_ATTRS)
CC_HDRS_ATTRS.update(_CC_COMPILABLE_ATTRS)
CC_HDRS_ATTRS.update(_CC_LIB_ATTRS)
CC_HDRS_ATTRS.pop("srcs")
