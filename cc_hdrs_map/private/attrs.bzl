""" Contains common configuration-related entities used by cc_hdrs_map rules. """

_COMMON_RULES_ATTRS = {
    "deps": struct(
        attr = attr.label_list(
            default = [],
            doc = "The list of dependencies of current target",
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("deps", getattr(ctx_attr, "deps", [])),
            link_to_archive = lambda ctx_attr: ("deps", getattr(ctx_attr, "deps", [])),
            link_to_bin = lambda ctx_attr: ("deps", getattr(ctx_attr, "deps", [])),
            link_to_so = lambda ctx_attr: ("deps", getattr(ctx_attr, "deps", [])),
        ),
    ),
    "srcs": struct(
        attr = attr.label_list(
            mandatory = True,
            allow_files = [
                ".c",
                ".cc",
                ".cpp",
                ".cxx",
                ".c++",
                ".C",
            ],
            doc = "The list of source files.",
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("srcs", [f for t in getattr(ctx_attr, "srcs", []) for f in t.files.to_list()]),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "public_hdrs": struct(
        attr = attr.label_list(
            allow_files = [
                ".h",
                ".hh",
                ".hpp",
                ".hxx",
                ".inc",
                ".inl",
                ".H",
            ],
            doc = """ 
        List of headers that may be included by dependent rules transitively.
        Notice: the cutoff happens during compilation.
        """,
            default = [],
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("public_hdrs", [f for t in getattr(ctx_attr, "public_hdrs", []) for f in t.files.to_list()]),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "private_hdrs": struct(
        attr = attr.label_list(
            allow_files = [
                ".h",
                ".hh",
                ".hpp",
                ".hxx",
                ".inc",
                ".inl",
                ".H",
            ],
            doc = """
        List of headers that CANNOT be included by dependent rules.
        Notice: the cutoff happens during compilation.
        """,
            default = [],
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("private_hdrs", [f for t in getattr(ctx_attr, "private_hdrs", []) for f in t.files.to_list()]),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "hdrs_map": struct(
        attr = attr.string_list_dict(
            default = {},
            doc = """
        Dictionary describing paths under which header files should be avaiable as.

        Keys are simple glob pathnames, used to match agains all header files avaiable in the rule.
        Values are list of paths to which matching header files should be mapped.

        '{filename}' is special token used to signify to matching file name.

        For example:
        '"**/*o.hpp": ["a/{filename}"]' - will ensure all hpp files with names ending with '0'
        will be also avaible as if they were placed in a subdirectory. 
        """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("hdrs_map", getattr(ctx_attr, "hdrs_map", {})),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
}

_CC_COMPILABLE_ATTRS = {
    "additional_linker_inputs": struct(
        attr = attr.label_list(
            default = [],
            doc = """
        Pass these files to the C++ linker command.

        For example, compiled Windows .res files can be provided here to be embedded in the binary target.
        """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: None,
            # TODO: I think it should be added
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: ("additional_inputs", getattr(ctx_attr, "additional_linker_inputs", [])),
            link_to_so = lambda ctx_attr: ("additional_inputs", getattr(ctx_attr, "additional_linker_inputs", [])),
        ),
    ),
    "conlyopts": struct(
        attr = attr.string_list(
            default = [],
            doc = """
            Add these options to the C compilation command. Subject to "Make variable" substitution and Bourne shell tokenization. 
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("conly_flags", getattr(ctx_attr, "conlyopts", [])),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "copts": struct(
        attr = attr.string_list(
            default = [],
            doc = """
            Add these options to the C++ compilation command. Subject to "Make variable" substitution and Bourne shell tokenization.
            Each string in this attribute is added in the given order to COPTS before compiling the binary target. The flags take effect only for compiling this target, not its dependencies, so be careful about header files included elsewhere. All paths should be relative to the workspace, not to the current package.

            If the package declares the feature no_copts_tokenization, Bourne shell tokenization applies only to strings that consist of a single "Make" variable.
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("user_compile_flags", getattr(ctx_attr, "copts", [])),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "cxxopts": struct(
        attr = attr.string_list(
            default = [],
            doc = """
            Add these options to the C++ compilation command. Subject to "Make variable" substitution and Bourne shell tokenization. 
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("cxx_flags", getattr(ctx_attr, "cxxopts", [])),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "defines": struct(
        attr = attr.string_list(
            default = [],
            doc = """
            List of defines to add to the compile line. Subject to "Make" variable substitution and Bourne shell tokenization. Each string, which must consist of a single Bourne shell token, is prepended with -D and added to the compile command line to this target, as well as to every rule that depends on it. Be very careful, since this may have far-reaching effects. When in doubt, add define values to local_defines instead.
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("defines", getattr(ctx_attr, "defines", [])),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    # TODO: Important!
    "dynamic_deps": struct(
        attr = attr.label_list(
            default = [],
            doc = """
            These are other cc_shared_library dependencies the current target depends on.

            The cc_shared_library implementation will use the list of dynamic_deps (transitively, i.e. also the dynamic_deps of the current target's dynamic_deps) to decide which cc_libraries in the transitive deps should not be linked in because they are already provided by a different cc_shared_library. 
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: None,
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "includes": struct(
        attr = attr.string_list(
            default = [],
            doc = """
            List of include dirs to be added to the compile line.
            Subject to "Make variable" substitution. Each string is prepended with -isystem and added to COPTS. Unlike COPTS, these flags are added for this rule and every rule that depends on it. (Note: not the rules it depends upon!) Be very careful, since this may have far-reaching effects. When in doubt, add "-I" flags to COPTS instead.

            Headers must be added to srcs or hdrs, otherwise they will not be available to dependent rules when compilation is sandboxed (the default).
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("includes", getattr(ctx_attr, "includes", [])),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    # TODO: Can I make it work?
    "link_extra_lib": struct(
        attr = attr.label(
            default = "@bazel_tools//tools/cpp:link_extra_lib",
            doc = """
            Control linking of extra libraries.

            By default, C++ binaries are linked against //tools/cpp:link_extra_lib, which by default depends on the label flag //tools/cpp:link_extra_libs. Without setting the flag, this library is empty by default. Setting the label flag allows linking optional dependencies, such as overrides for weak symbols, interceptors for shared library functions, or special runtime libraries (for malloc replacements, prefer malloc or --custom_malloc). Setting this attribute to None disables this behaviour. 
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: None,
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "linkopts": struct(
        attr = attr.string_list(
            default = [],
            doc = """
            Add these flags to the C++ linker command. Subject to "Make" variable substitution, Bourne shell tokenization and label expansion. Each string in this attribute is added to LINKOPTS before linking the binary target.
            Each element of this list that does not start with $ or - is assumed to be the label of a target in deps. The list of files generated by that target is appended to the linker options. An error is reported if the label is invalid, or is not declared in deps.
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: None,
            link_to_archive = lambda ctx_attr: ("user_link_flags", getattr(ctx_attr, "linkopts", [])),
            link_to_bin = lambda ctx_attr: ("user_link_flags", getattr(ctx_attr, "linkopts", [])),
            link_to_so = lambda ctx_attr: ("user_link_flags", getattr(ctx_attr, "linkopts", [])),
        ),
    ),
    "linkstatic": struct(
        attr = attr.bool(
            default = True,
            doc = "Link the binary in static mode.",
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: None,
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: ("link_deps_statically", getattr(ctx_attr, "linkstatic", True)),
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "local_defines": struct(
        attr = attr.string_list(
            default = [],
            doc = """
            List of defines to add to the compile line. Subject to "Make" variable substitution and Bourne shell tokenization. Each string, which must consist of a single Bourne shell token, is prepended with -D and added to the compile command line for this target, but not to its dependents.
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("local_defines", getattr(ctx_attr, "local_defines", [])),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    # TODO: Can I make it work?
    "malloc": struct(
        attr = attr.label(
            default = "@bazel_tools//tools/cpp:malloc",
            doc = """
            Override the default dependency on malloc.

            By default, C++ binaries are linked against //tools/cpp:malloc, which is an empty library so the binary ends up using libc malloc. This label must refer to a cc_library. If compilation is for a non-C++ rule, this option has no effect. The value of this attribute is ignored if linkshared=True is specified. 
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: None,
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    # TODO: support for module_interfaces
    # TODO: Can I make it  work?
    "nocopts": struct(
        attr = attr.string(
            default = "",
            doc = """
            Remove matching options from the C++ compilation command. Subject to "Make" variable substitution. The value of this attribute is interpreted as a regular expression. Any preexisting COPTS that match this regular expression (including values explicitly specified in the rule's copts attribute) will be removed from COPTS for purposes of compiling this rule. This attribute should not be needed or used outside of third_party. The values are not preprocessed in any way other than the "Make" variable substitution. 
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: None,
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    # TODO: Can I make it work?
    "reexport_deps": struct(
        attr = attr.label_list(
            default = [],
            doc = """
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: None,
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "_cc_toolchain": struct(
        attr = attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: None,
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "_is_windows": struct(
        attr = attr.bool(
            default = False,
            doc = "Signify Windows execution platform. To be improved upon (should not require manual input)",
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: getattr(ctx_attr, "_is_windows", False),
            link_to_archive = lambda ctx_attr: getattr(ctx_attr, "_is_windows", False),
            link_to_bin = lambda ctx_attr: getattr(ctx_attr, "_is_windows", False),
            link_to_so = lambda ctx_attr: getattr(ctx_attr, "_is_windows", False),
        ),
    ),
}

_CC_LIB_ATTRS = {
    "include_prefix": struct(
        attr = attr.string(
            default = "",
            doc = """
            The prefix to add to the paths of the headers of this rule.
            When set, the headers in the hdrs attribute of this rule are accessible at is the value of this attribute prepended to their repository-relative path.

            The prefix in the strip_include_prefix attribute is removed before this prefix is added.
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("include_prefix", getattr(ctx_attr, "include_prefix", None)),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "strip_include_prefix": struct(
        attr = attr.string(
            default = "",
            doc = """
            The prefix to strip from the paths of the headers of this rule.
            When set, the headers in the hdrs attribute of this rule are accessible at their path with this prefix cut off.

            If it's a relative path, it's taken as a package-relative one. If it's an absolute one, it's understood as a repository-relative path.

            The prefix in the include_prefix attribute is added after this prefix is stripped.
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("strip_include_prefix", getattr(ctx_attr, "strip_include_prefix", None)),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
}

def get_cc_bin_attrs():
    """ To be described """
    cc_bin_attrs = {
        "data": struct(
            attr = attr.label_list(
                default = [],
                doc = """
                The list of files needed by this library at runtime. See general comments about data at Typical attributes defined by most build rules.

                If a data is the name of a generated file, then this cc_library rule automatically depends on the generating rule.

                If a data is a rule name, then this cc_library rule automatically depends on that rule, and that rule's outs are automatically added to this cc_library's data files. 
                """,
            ),
            as_action_param = struct(
                compile = lambda ctx_attr: None,
                link_to_archive = lambda ctx_attr: None,
                link_to_bin = lambda ctx_attr: None,
                link_to_so = lambda ctx_attr: None,
            ),
        ),
        "stamp": struct(
            attr = attr.int(
                default = -1,
                doc = """
                    Whether to encode build information into the binary. Possible values:

                      * stamp = 1: Always stamp the build information into the binary, even in --nostamp builds. This setting should be avoided, since it potentially kills remote caching for the binary and any downstream actions that depend on it.

                      * stamp = 0: Always replace build information by constant values. This gives good build result caching.

                      * stamp = -1: Embedding of build information is controlled by the --[no]stamp flag.
            
                    Stamped binaries are not rebuilt unless their dependencies change.
                    """,
            ),
            as_action_param = struct(
                compile = lambda ctx_attr: None,
                link_to_archive = lambda ctx_attr: None,
                link_to_bin = lambda ctx_attr: ("stamp", getattr(ctx_attr, "stamp", -1)),
                link_to_so = lambda ctx_attr: None,
            ),
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
        "alwayslink": struct(
            attr = attr.bool(
                default = True,
                doc = """
                If 1, any binary that depends (directly or indirectly) on this C++ library will link in all the object files for the files listed in srcs, even if some contain no symbols referenced by the binary. This is useful if your code isn't explicitly called by code in the binary, e.g., if your code registers to receive some callback provided by some service.
                """,
            ),
            as_action_param = struct(
                compile = lambda ctx_attr: None,
                link_to_archive = lambda ctx_attr: None,
                link_to_bin = lambda ctx_attr: None,
                link_to_so = lambda ctx_attr: ("alwayslink", getattr(ctx_attr, "alwayslink", False)),
            ),
        ),
        "shared_lib_name": struct(
            attr = attr.string(
                default = "",
                doc = """
                This allows to override the library name. <A further description of how it deals with custom suffixes to come>
                """,
            ),
            as_action_param = struct(
                compile = lambda ctx_attr: None,
                link_to_archive = lambda ctx_attr: None,
                link_to_bin = lambda ctx_attr: None,
                link_to_so = lambda ctx_attr: ("shared_lib_name", getattr(ctx_attr, "shared_lib_name", "")),
            ),
        ),
    }
    cc_so_attrs.update(_COMMON_RULES_ATTRS)
    cc_so_attrs.update(_CC_COMPILABLE_ATTRS)
    cc_so_attrs.update(_CC_LIB_ATTRS)
    return cc_so_attrs

def get_cc_archive_attrs():
    """ To be described. """
    cc_archive_attrs = {}
    cc_archive_attrs.update(_COMMON_RULES_ATTRS)
    cc_archive_attrs.update(_CC_COMPILABLE_ATTRS)
    cc_archive_attrs.update(_CC_LIB_ATTRS)
    return cc_archive_attrs
