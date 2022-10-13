<!-- Generated with Stardoc: http://skydoc.bazel.build -->

 Module providing means of creating archive files which use mapping metadata. 

<a id="cc_archive"></a>

## cc_archive

<pre>
cc_archive(<a href="#cc_archive-name">name</a>, <a href="#cc_archive-additional_linker_inputs">additional_linker_inputs</a>, <a href="#cc_archive-copts">copts</a>, <a href="#cc_archive-defines">defines</a>, <a href="#cc_archive-deps">deps</a>, <a href="#cc_archive-hdrs_map">hdrs_map</a>, <a href="#cc_archive-include_prefix">include_prefix</a>, <a href="#cc_archive-includes">includes</a>,
           <a href="#cc_archive-linkopts">linkopts</a>, <a href="#cc_archive-linkstatic">linkstatic</a>, <a href="#cc_archive-local_defines">local_defines</a>, <a href="#cc_archive-private_hdrs">private_hdrs</a>, <a href="#cc_archive-public_hdrs">public_hdrs</a>, <a href="#cc_archive-srcs">srcs</a>, <a href="#cc_archive-strip_include_prefix">strip_include_prefix</a>)
</pre>


This rule allows for creating archive objects,
which can utilize the headers map and propagate them
futher down the dependency chain.

Example:
```python
cc_archive(
    name = "foo",
    hdrs_map = {
        "**/*.hpp": ["bar/{filename}"],
    },
    deps = [
        ":foo_hdrs",
    ],
    srcs = [
        "foo.cpp",
    ],
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_archive-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cc_archive-additional_linker_inputs"></a>additional_linker_inputs |  Pass these files to the C++ linker command.<br><br>        For example, compiled Windows .res files can be provided here to be embedded in the binary target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_archive-copts"></a>copts |  Add these options to the C++ compilation command. Subject to "Make variable" substitution and Bourne shell tokenization.         Each string in this attribute is added in the given order to COPTS before compiling the binary target. The flags take effect only for compiling this target, not its dependencies, so be careful about header files included elsewhere. All paths should be relative to the workspace, not to the current package.<br><br>        If the package declares the feature no_copts_tokenization, Bourne shell tokenization applies only to strings that consist of a single "Make" variable.   | List of strings | optional | [] |
| <a id="cc_archive-defines"></a>defines |  List of defines to add to the compile line. Subject to "Make" variable substitution and Bourne shell tokenization. Each string, which must consist of a single Bourne shell token, is prepended with -D and added to the compile command line to this target, as well as to every rule that depends on it. Be very careful, since this may have far-reaching effects. When in doubt, add define values to local_defines instead.   | List of strings | optional | [] |
| <a id="cc_archive-deps"></a>deps |  The list of dependencies of current target   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_archive-hdrs_map"></a>hdrs_map |  Dictionary describing paths under which header files should be avaiable as.<br><br>        Keys are simple glob pathnames, used to match agains all header files avaiable in the rule.         Values are list of paths to which matching header files should be mapped.<br><br>        '{filename}' is special token used to signify to matching file name.<br><br>        For example:         '"**/*o.hpp": ["a/{filename}"]' - will ensure all hpp files with names ending with '0'         will be also avaible as if they were placed in a subdirectory.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional | {} |
| <a id="cc_archive-include_prefix"></a>include_prefix |  The prefix to add to the paths of the headers of this rule.         When set, the headers in the hdrs attribute of this rule are accessible at is the value of this attribute prepended to their repository-relative path.<br><br>        The prefix in the strip_include_prefix attribute is removed before this prefix is added.   | String | optional | "" |
| <a id="cc_archive-includes"></a>includes |  List of include dirs to be added to the compile line.         Subject to "Make variable" substitution. Each string is prepended with -isystem and added to COPTS. Unlike COPTS, these flags are added for this rule and every rule that depends on it. (Note: not the rules it depends upon!) Be very careful, since this may have far-reaching effects. When in doubt, add "-I" flags to COPTS instead.<br><br>        Headers must be added to srcs or hdrs, otherwise they will not be available to dependent rules when compilation is sandboxed (the default).   | List of strings | optional | [] |
| <a id="cc_archive-linkopts"></a>linkopts |  Add these flags to the C++ linker command. Subject to "Make" variable substitution, Bourne shell tokenization and label expansion. Each string in this attribute is added to LINKOPTS before linking the binary target.         Each element of this list that does not start with $ or - is assumed to be the label of a target in deps. The list of files generated by that target is appended to the linker options. An error is reported if the label is invalid, or is not declared in deps.   | List of strings | optional | [] |
| <a id="cc_archive-linkstatic"></a>linkstatic |  Link the binary in static mode.   | Boolean | optional | True |
| <a id="cc_archive-local_defines"></a>local_defines |  List of defines to add to the compile line. Subject to "Make" variable substitution and Bourne shell tokenization. Each string, which must consist of a single Bourne shell token, is prepended with -D and added to the compile command line for this target, but not to its dependents.   | List of strings | optional | [] |
| <a id="cc_archive-private_hdrs"></a>private_hdrs |  List of headers that CANNOT be included by dependent rules.         Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_archive-public_hdrs"></a>public_hdrs |  List of headers that may be included by dependent rules transitively.         Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_archive-srcs"></a>srcs |  The list of source files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="cc_archive-strip_include_prefix"></a>strip_include_prefix |  The prefix to strip from the paths of the headers of this rule.         When set, the headers in the hdrs attribute of this rule are accessible at their path with this prefix cut off.<br><br>        If it's a relative path, it's taken as a package-relative one. If it's an absolute one, it's understood as a repository-relative path.<br><br>        The prefix in the include_prefix attribute is added after this prefix is stripped.   | String | optional | "" |


