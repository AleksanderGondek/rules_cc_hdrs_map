""" Contains common configuration-related entities used by cc_hdrs_map rules. """

load("@rules_cc_hdrs_map//cc_hdrs_map/actions:cc_helper.bzl", "CC_HEADER_EXTENSIONS", "CC_SOURCE_EXTENSIONS", "cc_helper")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl", "new_hdrs_map")

def _not_yet_implemented(ctx_attr, attr_name):
    if bool(getattr(ctx_attr, attr_name, None)):
        print("[WARN] The attribute of '{}' is not yet implemented for rules_cc_hdrs_map.".format(attr_name))
    return None

def _will_not_implement(ctx_attr, attr_name):
    if bool(getattr(ctx_attr, attr_name, None)):
        fail("[ERROR] The attribute of '{}' will not be implemented for rules_cc_hdrs_map.".format(attr_name))
    return None

_COMMON_RULES_ATTRS = {
    "data": struct(
        attr = attr.label_list(
            allow_files = True,
            default = [],
            doc = """
                The list of files needed by this target at runtime. See general comments about data at Typical attributes defined by most build rules.
                """,
        ),
        # This parameter is handled by common logic, no need to pass it onto the dedicated actions (subrules)
        as_action_param = struct(
            compile = lambda ctx_attr: None,
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
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
            # Perhaps in future we can disallow headers here
            allow_files = CC_SOURCE_EXTENSIONS + CC_HEADER_EXTENSIONS,
            doc = "The list of source files.",
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("srcs", [f for t in getattr(ctx_attr, "srcs", []) for f in t.files.to_list()]),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "hdrs": struct(
        attr = attr.label_list(
            allow_files = CC_HEADER_EXTENSIONS,
            doc = """ 
        List of headers that may be included by dependent rules transitively.
        Notice: the cutoff happens during compilation.
        """,
            default = [],
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("hdrs", [f for t in getattr(ctx_attr, "hdrs", []) for f in t.files.to_list()]),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "implementation_hdrs": struct(
        attr = attr.label_list(
            allow_files = CC_HEADER_EXTENSIONS,
            doc = """
        List of headers that CANNOT be included by dependent rules.
        Notice: the cutoff happens during compilation.
        """,
            default = [],
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("implementation_hdrs", [f for t in getattr(ctx_attr, "implementation_hdrs", []) for f in t.files.to_list()]),
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
            compile = lambda ctx_attr: ("hdrs_map", new_hdrs_map(from_dict = getattr(ctx_attr, "hdrs_map", {}))),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "module_interfaces": struct(
        attr = attr.label_list(
            doc = """
        The list of files that are regarded as C++20 Modules Interface.

        C++ Standard has no restriction about module interface file extension
        * Clang use cppm
        * GCC can use any source file extension
        * MSVC use ixx

        The use is guarded by the flag --experimental_cpp_modules.
        """,
            default = [],
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: _not_yet_implemented(ctx_attr, "module_interfaces"),
            link_to_archive = lambda ctx_attr: _not_yet_implemented(ctx_attr, "module_interfaces"),
            link_to_bin = lambda ctx_attr: _not_yet_implemented(ctx_attr, "module_interfaces"),
            link_to_so = lambda ctx_attr: _not_yet_implemented(ctx_attr, "module_interfaces"),
        ),
    ),
    "win_def_file": struct(
        attr = attr.label(
            doc = """
        The Windows DEF file to be passed to linker.

        This attribute should only be used when Windows is the target platform. It can be used to export symbols during linking a shared library.
        """,
            default = None,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: _will_not_implement(ctx_attr, "win_def_file"),
            link_to_archive = lambda ctx_attr: _will_not_implement(ctx_attr, "win_def_file"),
            link_to_bin = lambda ctx_attr: _will_not_implement(ctx_attr, "win_def_file"),
            link_to_so = lambda ctx_attr: _will_not_implement(ctx_attr, "win_def_file"),
        ),
    ),
}

_CC_COMPILABLE_ATTRS = {
    "additional_compiler_inputs": struct(
        attr = attr.label_list(
            allow_files = True,
            default = [],
            doc = """
            Any additional files you might want to pass to the compiler command line, such as sanitizer ignorelists, for example.
            Files specified here can then be used in copts with the $(location) function. 
        """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: ("additional_inputs", getattr(ctx_attr, "additional_compiler_inputs")),
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: None,
            link_to_so = lambda ctx_attr: None,
        ),
    ),
    "additional_linker_inputs": struct(
        attr = attr.label_list(
            allow_files = True,
            default = [],
            doc = """
            Any additional files that you may want to pass to the linker, for example, linker scripts.
            You have to separately pass any linker flags that the linker needs in order to be aware of this file.
            You can do so via the linkopts attribute.
        """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: None,
            link_to_archive = lambda ctx_attr: ("additional_inputs", getattr(ctx_attr, "additional_linker_inputs", [])),
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
        expand_make_variables = lambda ctx, cc_info, action_kwargs: ("conly_flags", cc_helper.expand_make_variables_in_copts(ctx, cc_info, action_kwargs, action_kwargs.get("conly_flags"))),
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
        expand_make_variables = lambda ctx, cc_info, action_kwargs: ("user_compile_flags", cc_helper.expand_make_variables_in_copts(ctx, cc_info, action_kwargs, action_kwargs.get("user_compile_flags"))),
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
        expand_make_variables = lambda ctx, cc_info, action_kwargs: ("cxx_flags", cc_helper.expand_make_variables_in_copts(ctx, cc_info, action_kwargs, action_kwargs.get("cxx_flags"))),
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
        expand_make_variables = lambda ctx, cc_info, action_kwargs: ("defines", cc_helper.expand_make_variables_in_defines(ctx, cc_info, action_kwargs, action_kwargs.get("defines"))),
    ),
    "dynamic_deps": struct(
        attr = attr.label_list(
            default = [],
            doc = """
            In contrast to `rules_cc`, the dynamic_deps of `rules_cc_hdrs_map` are simply translated into deps parameter,
            and the providers (CcInfo vs CcSharedInfo) are used to steer the behavior further.
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: None,
            link_to_archive = lambda ctx_attr: None,
            link_to_bin = lambda ctx_attr: ("deps", getattr(ctx_attr, "dynamic_deps", [])),
            link_to_so = lambda ctx_attr: ("deps", getattr(ctx_attr, "dynamic_deps", [])),
        ),
    ),
    "implementation_deps": struct(
        attr = attr.label_list(
            default = [],
            doc = """
            The list of other libraries that the library target depends on. Unlike with deps, the headers and include paths of these libraries (and all their transitive deps) are only used for compilation of this library, and not libraries that depend on it. Libraries specified with implementation_deps are still linked in binary targets that depend on this library.
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: _not_yet_implemented(ctx_attr, "implementation_deps"),
            link_to_archive = lambda ctx_attr: _not_yet_implemented(ctx_attr, "implementation_deps"),
            link_to_bin = lambda ctx_attr: _not_yet_implemented(ctx_attr, "implementation_deps"),
            link_to_so = lambda ctx_attr: _not_yet_implemented(ctx_attr, "implementation_deps"),
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
    "link_extra_lib": struct(
        attr = attr.label(
            doc = """
            Control linking of extra libraries.

            By default, C++ binaries are linked against //tools/cpp:link_extra_lib, which by default depends on the label flag //tools/cpp:link_extra_libs. Without setting the flag, this library is empty by default. Setting the label flag allows linking optional dependencies, such as overrides for weak symbols, interceptors for shared library functions, or special runtime libraries (for malloc replacements, prefer malloc or --custom_malloc). Setting this attribute to None disables this behaviour. 
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: _not_yet_implemented(ctx_attr, "link_extra_libs"),
            link_to_archive = lambda ctx_attr: _not_yet_implemented(ctx_attr, "link_extra_libs"),
            link_to_bin = lambda ctx_attr: _not_yet_implemented(ctx_attr, "link_extra_libs"),
            link_to_so = lambda ctx_attr: _not_yet_implemented(ctx_attr, "link_extra_libs"),
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
        expand_make_variables = lambda ctx, cc_info, action_kwargs: ("user_link_flags", cc_helper.expand_make_variables_in_linkopts(ctx, cc_info, action_kwargs, action_kwargs.get("user_link_flags"))),
    ),
    "linkshared": struct(
        attr = attr.bool(
            default = False,
            doc = """
            Create a shared library. To enable this attribute, include linkshared=True in your rule. By default this option is off. 
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: _will_not_implement(ctx_attr, "linkshared"),
            link_to_archive = lambda ctx_attr: _will_not_implement(ctx_attr, "linkshared"),
            link_to_bin = lambda ctx_attr: _will_not_implement(ctx_attr, "linkshared"),
            link_to_so = lambda ctx_attr: _will_not_implement(ctx_attr, "linkshared"),
        ),
    ),
    "linkstamp": struct(
        attr = attr.label(
            default = None,
            doc = """
            Simultaneously compiles and links the specified C++ source file into the final binary. This trickery is required to introduce timestamp information into binaries; if we compiled the source file to an object file in the usual way, the timestamp would be incorrect. A linkstamp compilation may not include any particular set of compiler flags and so should not depend on any particular header, compiler option, or other build variable. This option should only be needed in the base package.
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: _not_yet_implemented(ctx_attr, "linkstamp"),
            link_to_archive = lambda ctx_attr: _not_yet_implemented(ctx_attr, "linkstamp"),
            link_to_bin = lambda ctx_attr: _not_yet_implemented(ctx_attr, "linkstamp"),
            link_to_so = lambda ctx_attr: _not_yet_implemented(ctx_attr, "linkstamp"),
        ),
    ),
    "linkstatic": struct(
        attr = attr.bool(
            default = False,
            doc = """
            If enabled and this is a binary or test, this option tells the build tool to link in .a's instead of .so's for user libraries whenever possible. System libraries such as libc (but not the C/C++ runtime libraries, see below) are still linked dynamically, as are libraries for which there is no static library. So the resulting executable will still be dynamically linked, hence only mostly static.
            The linkstatic attribute has a different meaning if used on a cc_library() rule. For a C++ library, linkstatic=True indicates that only static linking is allowed, so no .so will be produced. linkstatic=False does not prevent static libraries from being created. The attribute is meant to control the creation of dynamic libraries. 
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: _will_not_implement(ctx_attr, "linkstatic"),
            link_to_archive = lambda ctx_attr: _will_not_implement(ctx_attr, "linkstatic"),
            link_to_bin = lambda ctx_attr: _will_not_implement(ctx_attr, "linkstatic"),
            link_to_so = lambda ctx_attr: _will_not_implement(ctx_attr, "linkstatic"),
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
        expand_make_variables = lambda ctx, cc_info, action_kwargs: ("local_defines", cc_helper.expand_make_variables_in_defines(ctx, cc_info, action_kwargs, action_kwargs.get("local_defines"), local = True)),
    ),
    "malloc": struct(
        attr = attr.label(
            doc = """
            Override the default dependency on malloc.

            By default, C++ binaries are linked against //tools/cpp:malloc, which is an empty library so the binary ends up using libc malloc. This label must refer to a cc_library. If compilation is for a non-C++ rule, this option has no effect. The value of this attribute is ignored if linkshared=True is specified. 
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: _not_yet_implemented(ctx_attr, "malloc"),
            link_to_archive = lambda ctx_attr: _not_yet_implemented(ctx_attr, "malloc"),
            link_to_bin = lambda ctx_attr: _not_yet_implemented(ctx_attr, "malloc"),
            link_to_so = lambda ctx_attr: _not_yet_implemented(ctx_attr, "mallco"),
        ),
    ),
    "nocopts": struct(
        attr = attr.string(
            default = "",
            doc = """
            Remove matching options from the C++ compilation command. Subject to "Make" variable substitution. The value of this attribute is interpreted as a regular expression. Any preexisting COPTS that match this regular expression (including values explicitly specified in the rule's copts attribute) will be removed from COPTS for purposes of compiling this rule. This attribute should not be needed or used outside of third_party. The values are not preprocessed in any way other than the "Make" variable substitution. 
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: _not_yet_implemented(ctx_attr, "nocopts"),
            link_to_archive = lambda ctx_attr: _not_yet_implemented(ctx_attr, "nocopts"),
            link_to_bin = lambda ctx_attr: _not_yet_implemented(ctx_attr, "nocopts"),
            link_to_so = lambda ctx_attr: _not_yet_implemented(ctx_attr, "nocopts"),
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
    "textual_hdrs": struct(
        attr = attr.label_list(
            default = [],
            doc = """
            The list of header files published by this library to be textually included by sources in dependent rules.

            This is the location for declaring header files that cannot be compiled on their own; that is, they always need to be textually included by other source files to build valid code.
            """,
        ),
        as_action_param = struct(
            compile = lambda ctx_attr: _not_yet_implemented(ctx_attr, "textual_hdrs"),
            link_to_archive = lambda ctx_attr: _not_yet_implemented(ctx_attr, "textual_hdrs"),
            link_to_bin = lambda ctx_attr: _not_yet_implemented(ctx_attr, "textual_hdrs"),
            link_to_so = lambda ctx_attr: _not_yet_implemented(ctx_attr, "textual_hdrs"),
        ),
    ),
}

def get_cc_bin_attrs():
    """ To be described """
    cc_bin_attrs = {
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
        "reexport_deps": struct(
            attr = attr.label_list(
                default = [],
                doc = "",
            ),
            as_action_param = struct(
                compile = lambda ctx_attr: _not_yet_implemented(ctx_attr, "reexport_deps"),
                link_to_archive = lambda ctx_attr: _not_yet_implemented(ctx_attr, "reexport_deps"),
                link_to_bin = lambda ctx_attr: _not_yet_implemented(ctx_attr, "reexport_deps"),
                link_to_so = lambda ctx_attr: _not_yet_implemented(ctx_attr, "reexport_deps"),
            ),
        ),
    }
    cc_bin_attrs.update(_COMMON_RULES_ATTRS)
    cc_bin_attrs.update(_CC_COMPILABLE_ATTRS)
    cc_bin_attrs.pop("implementation_deps")
    cc_bin_attrs.pop("implementation_hdrs")
    cc_bin_attrs.pop("linkstamp")
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
                default = False,
                doc = """
                If 1, any binary that depends (directly or indirectly) on this C++ precompiled library will link in all the object files archived in the static library, even if some contain no symbols referenced by the binary. This is useful if your code isn't explicitly called by code in the binary, e.g., if your code registers to receive some callback provided by some service. 
                """,
            ),
            as_action_param = struct(
                compile = lambda ctx_attr: _not_yet_implemented(ctx_attr, "always_link"),
                link_to_archive = lambda ctx_attr: _not_yet_implemented(ctx_attr, "always_link"),
                link_to_bin = lambda ctx_attr: _not_yet_implemented(ctx_attr, "always_link"),
                link_to_so = lambda ctx_attr: _not_yet_implemented(ctx_attr, "always_link"),
            ),
        ),
        "exports_filter": struct(
            attr = attr.string_list(
                default = [],
                doc = """
                This attribute contains a list of targets that are claimed to be exported by the current shared library.

                Any target deps is already understood to be exported by the shared library. This attribute should be used to list any targets that are exported by the shared library but are transitive dependencies of deps.

                Note that this attribute is not actually adding a dependency edge to those targets, the dependency edge should instead be created by deps.The entries in this attribute are just strings. Keep in mind that when placing a target in this attribute, this is considered a claim that the shared library exports the symbols from that target. The cc_shared_library logic doesn't actually handle telling the linker which symbols should be exported.

                The following syntax is allowed:

                //foo:__pkg__ to account for any target in foo/BUILD

                //foo:__subpackages__ to account for any target in foo/BUILD or any other package below foo/ like foo/bar/BUILD
                """,
            ),
            as_action_param = struct(
                compile = lambda ctx_attr: _not_yet_implemented(ctx_attr, "exports_filter"),
                link_to_archive = lambda ctx_attr: _not_yet_implemented(ctx_attr, "exports_filter"),
                link_to_bin = lambda ctx_attr: _not_yet_implemented(ctx_attr, "exports_filter"),
                link_to_so = lambda ctx_attr: _not_yet_implemented(ctx_attr, "exports_filter"),
            ),
        ),
        "roots": struct(
            attr = attr.label_list(
                default = [],
                doc = """(Not yet implemented)""",
            ),
            as_action_param = struct(
                compile = lambda ctx_attr: _not_yet_implemented(ctx_attr, "roots"),
                link_to_archive = lambda ctx_attr: _not_yet_implemented(ctx_attr, "roots"),
                link_to_bin = lambda ctx_attr: _not_yet_implemented(ctx_attr, "roots"),
                link_to_so = lambda ctx_attr: _not_yet_implemented(ctx_attr, "roots"),
            ),
        ),
        "shared_lib_name": struct(
            attr = attr.string(
                default = "",
                doc = """
                Specify the name of the created SOL file (that is decoupled from the rule instance name).
                Note, that the 'cc_so' is opinionated and will remove any leading 'lib' prefix and any '.so' in the name
                (meaning 'libTest.so.x64.so' will become 'Test.x64' and will produce 'libTest.x64.so')
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
    cc_archive_attrs = {
        "archive_lib_name": struct(
            attr = attr.string(
                default = "",
                doc = """
                Specify the name of the created .a file (that is decoupled from the rule instance name).
                Note, that the 'cc_archive' is opinionated and will remove any leading 'lib' prefix and any '.a' in the name
                (meaning 'libTest.a.x64.a' will become 'Test.x64' and will produce 'libTest.x64.a')
                """,
            ),
            as_action_param = struct(
                compile = lambda ctx_attr: None,
                link_to_archive = lambda ctx_attr: ("archive_lib_name", getattr(ctx_attr, "archive_lib_name", "")),
                link_to_bin = lambda ctx_attr: None,
                link_to_so = lambda ctx_attr: None,
            ),
        ),
        "reexport_deps": struct(
            attr = attr.label_list(
                default = [],
                doc = "",
            ),
            as_action_param = struct(
                compile = lambda ctx_attr: _not_yet_implemented(ctx_attr, "reexport_deps"),
                link_to_archive = lambda ctx_attr: _not_yet_implemented(ctx_attr, "reexport_deps"),
                link_to_bin = lambda ctx_attr: _not_yet_implemented(ctx_attr, "reexport_deps"),
                link_to_so = lambda ctx_attr: _not_yet_implemented(ctx_attr, "reexport_deps"),
            ),
        ),
    }
    cc_archive_attrs.update(_COMMON_RULES_ATTRS)
    cc_archive_attrs.update(_CC_COMPILABLE_ATTRS)
    cc_archive_attrs.update(_CC_LIB_ATTRS)
    cc_archive_attrs.pop("link_extra_lib")
    cc_archive_attrs.pop("malloc")
    return cc_archive_attrs
