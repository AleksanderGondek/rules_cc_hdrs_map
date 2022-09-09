""" Contains common configuration-related entities used by cc_hdrs_map rules. """

COMMON_RULES_ATTRS = {
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