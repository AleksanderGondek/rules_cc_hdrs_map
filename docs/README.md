<!-- Generated with Stardoc: http://skydoc.bazel.build -->

rules_cc_hdrs_map
---
[![ci](https://github.com/AleksanderGondek/rules_cc_hdrs_map/actions/workflows/ci.yaml/badge.svg)](https://github.com/AleksanderGondek/rules_cc_hdrs_map/actions/workflows/ci.yaml)

This project extends Bazel `CC` build capabilities with headers map implementation (allowing for easy support for most bizzare include path schemes).

In addition, it exposes CC compilation and linking functions in form of Bazel [subrules](https://docs.google.com/document/d/1RbNC88QieKvBEwir7iV5zZU08AaMlOzxhVkPnmKDedQ).

See [examples](/examples) for how to use `rules_cc_hdrs_map` (and why).

## Shortest possible example

```
$ cat foo.hpp
const std::string GREETINGS = "Hello";

$ cat foo.cpp
#include "bar/foo.h"
...

$ cat BUILD.bazel
load("@rules_cc_hdrs_map//cc_hdrs_map:defs.bzl", "cc_bin")

cc_bin(
    name = "foo",
    srcs = [
        "foo.hpp",
        "foo.cpp",
    ],
    hdrs_map = {
        "**/foo.hpp": ["bar/{filename}"],
    }
)

```

## Table of contents
1. [What issue is being addressed?](#what-issue-is-being-addressed)
2. [How the issue is being addressed?](#what-issue-is-being-addressed)
3. [What issue is being addressed?](#how-the-issue-is-being-addressed)
4. Rules
    1. [cc_archive](#cc_archive)
    2. [cc_bin](#cc_bin)
    3. [cc_hdrs](#cc_hdrs)
    4. [cc_so](#cc_so)
5. [HdrsMapInfo provider](#hdrsmapinfo)

## What issue is being addressed?

Creation of arbitrary include paths from existing sources.

_Scenario_: we want to build a C/CPP codebase with Bazel.

One of its key characteristics is that most of the include statements do not reflect the code structure in the project - for example, header file located under path “name/a.hpp” is never included as “name/a.hpp”, instead an arbitrary list of aliases is used in the code (“x/y/z/a.hpp”, “b.hpp” etc.).  There is no overarching convention that could be used to generalize those statements into another file file hierarchy - in other words, every header file is a special case of its own.

Unfortunately we are forbidden from modifying the code itself and the directory structure (hello from enterprise word).

As Bazel `rules_cc` have the expectation of header files being included in a way that resembles the file structure in the WORKSPACE (and one can only provide single “include prefix” per library), we need to prepare the “expected file structure” before passing them into the `rules_cc`.

In the most naive approach, said “expected file structure” is being prepared for each compilable target (copying over files), passing on the already created structure to targets that depend on it. Very quickly conflicts occur and change of a single header file may cascade into rebuilding hundreds of targets.

There has to be a better way!

## How the issue is being addressed?

The concept of header map is introduced - it is a dictionary, containing mapping between simple glob paths and their desired include paths. For example: “**/a.hpp”: “x/y/z/a.hpp” expresses the intent to import any header file with name “a.hpp”, present during compilation , as “x/y/z/a.hpp”.

Said header map is propagated across all compatible C/C++ rules (meaning those from this WORKSPACE) and is being merged with all other header maps present.

No action is being performed up until the moment of compilation - header mappings, resulting from the header map dictionary, are created only for the purposes of compilation and are _NOT_ part of any rule output. This ensures the impact for the Bazel cache is minimal and the compatibility with original `rules_cc`.

<a id="cc_archive"></a>

## cc_archive

<pre>
load("@rules_cc_hdrs_map//cc_hdrs_map:defs.bzl", "cc_archive")

cc_archive(<a href="#cc_archive-name">name</a>, <a href="#cc_archive-deps">deps</a>, <a href="#cc_archive-srcs">srcs</a>, <a href="#cc_archive-additional_linker_inputs">additional_linker_inputs</a>, <a href="#cc_archive-conlyopts">conlyopts</a>, <a href="#cc_archive-copts">copts</a>, <a href="#cc_archive-cxxopts">cxxopts</a>, <a href="#cc_archive-defines">defines</a>,
           <a href="#cc_archive-dynamic_deps">dynamic_deps</a>, <a href="#cc_archive-hdrs_map">hdrs_map</a>, <a href="#cc_archive-include_prefix">include_prefix</a>, <a href="#cc_archive-includes">includes</a>, <a href="#cc_archive-link_extra_lib">link_extra_lib</a>, <a href="#cc_archive-linkopts">linkopts</a>, <a href="#cc_archive-linkstatic">linkstatic</a>,
           <a href="#cc_archive-local_defines">local_defines</a>, <a href="#cc_archive-malloc">malloc</a>, <a href="#cc_archive-nocopts">nocopts</a>, <a href="#cc_archive-private_hdrs">private_hdrs</a>, <a href="#cc_archive-public_hdrs">public_hdrs</a>, <a href="#cc_archive-reexport_deps">reexport_deps</a>,
           <a href="#cc_archive-strip_include_prefix">strip_include_prefix</a>)
</pre>

Produce an archive file.

The intended major difference between this rule and rules_cc's `cc_static_library`,
is that this rule does not intend to pull-in all static dependencies.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_archive-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cc_archive-deps"></a>deps |  The list of dependencies of current target   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_archive-srcs"></a>srcs |  The list of source files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="cc_archive-additional_linker_inputs"></a>additional_linker_inputs |  Pass these files to the C++ linker command.<br><br>For example, compiled Windows .res files can be provided here to be embedded in the binary target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_archive-conlyopts"></a>conlyopts |  Add these options to the C compilation command. Subject to "Make variable" substitution and Bourne shell tokenization.   | List of strings | optional |  `[]`  |
| <a id="cc_archive-copts"></a>copts |  Add these options to the C++ compilation command. Subject to "Make variable" substitution and Bourne shell tokenization. Each string in this attribute is added in the given order to COPTS before compiling the binary target. The flags take effect only for compiling this target, not its dependencies, so be careful about header files included elsewhere. All paths should be relative to the workspace, not to the current package.<br><br>If the package declares the feature no_copts_tokenization, Bourne shell tokenization applies only to strings that consist of a single "Make" variable.   | List of strings | optional |  `[]`  |
| <a id="cc_archive-cxxopts"></a>cxxopts |  Add these options to the C++ compilation command. Subject to "Make variable" substitution and Bourne shell tokenization.   | List of strings | optional |  `[]`  |
| <a id="cc_archive-defines"></a>defines |  List of defines to add to the compile line. Subject to "Make" variable substitution and Bourne shell tokenization. Each string, which must consist of a single Bourne shell token, is prepended with -D and added to the compile command line to this target, as well as to every rule that depends on it. Be very careful, since this may have far-reaching effects. When in doubt, add define values to local_defines instead.   | List of strings | optional |  `[]`  |
| <a id="cc_archive-dynamic_deps"></a>dynamic_deps |  These are other cc_shared_library dependencies the current target depends on.<br><br>The cc_shared_library implementation will use the list of dynamic_deps (transitively, i.e. also the dynamic_deps of the current target's dynamic_deps) to decide which cc_libraries in the transitive deps should not be linked in because they are already provided by a different cc_shared_library.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_archive-hdrs_map"></a>hdrs_map |  Dictionary describing paths under which header files should be avaiable as.<br><br>Keys are simple glob pathnames, used to match agains all header files avaiable in the rule. Values are list of paths to which matching header files should be mapped.<br><br>'{filename}' is special token used to signify to matching file name.<br><br>For example: '"**/*o.hpp": ["a/{filename}"]' - will ensure all hpp files with names ending with '0' will be also avaible as if they were placed in a subdirectory.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional |  `{}`  |
| <a id="cc_archive-include_prefix"></a>include_prefix |  The prefix to add to the paths of the headers of this rule. When set, the headers in the hdrs attribute of this rule are accessible at is the value of this attribute prepended to their repository-relative path.<br><br>The prefix in the strip_include_prefix attribute is removed before this prefix is added.   | String | optional |  `""`  |
| <a id="cc_archive-includes"></a>includes |  List of include dirs to be added to the compile line. Subject to "Make variable" substitution. Each string is prepended with -isystem and added to COPTS. Unlike COPTS, these flags are added for this rule and every rule that depends on it. (Note: not the rules it depends upon!) Be very careful, since this may have far-reaching effects. When in doubt, add "-I" flags to COPTS instead.<br><br>Headers must be added to srcs or hdrs, otherwise they will not be available to dependent rules when compilation is sandboxed (the default).   | List of strings | optional |  `[]`  |
| <a id="cc_archive-link_extra_lib"></a>link_extra_lib |  Control linking of extra libraries.<br><br>By default, C++ binaries are linked against //tools/cpp:link_extra_lib, which by default depends on the label flag //tools/cpp:link_extra_libs. Without setting the flag, this library is empty by default. Setting the label flag allows linking optional dependencies, such as overrides for weak symbols, interceptors for shared library functions, or special runtime libraries (for malloc replacements, prefer malloc or --custom_malloc). Setting this attribute to None disables this behaviour.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@bazel_tools//tools/cpp:link_extra_lib"`  |
| <a id="cc_archive-linkopts"></a>linkopts |  Add these flags to the C++ linker command. Subject to "Make" variable substitution, Bourne shell tokenization and label expansion. Each string in this attribute is added to LINKOPTS before linking the binary target. Each element of this list that does not start with $ or - is assumed to be the label of a target in deps. The list of files generated by that target is appended to the linker options. An error is reported if the label is invalid, or is not declared in deps.   | List of strings | optional |  `[]`  |
| <a id="cc_archive-linkstatic"></a>linkstatic |  Link the binary in static mode.   | Boolean | optional |  `True`  |
| <a id="cc_archive-local_defines"></a>local_defines |  List of defines to add to the compile line. Subject to "Make" variable substitution and Bourne shell tokenization. Each string, which must consist of a single Bourne shell token, is prepended with -D and added to the compile command line for this target, but not to its dependents.   | List of strings | optional |  `[]`  |
| <a id="cc_archive-malloc"></a>malloc |  Override the default dependency on malloc.<br><br>By default, C++ binaries are linked against //tools/cpp:malloc, which is an empty library so the binary ends up using libc malloc. This label must refer to a cc_library. If compilation is for a non-C++ rule, this option has no effect. The value of this attribute is ignored if linkshared=True is specified.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@bazel_tools//tools/cpp:malloc"`  |
| <a id="cc_archive-nocopts"></a>nocopts |  Remove matching options from the C++ compilation command. Subject to "Make" variable substitution. The value of this attribute is interpreted as a regular expression. Any preexisting COPTS that match this regular expression (including values explicitly specified in the rule's copts attribute) will be removed from COPTS for purposes of compiling this rule. This attribute should not be needed or used outside of third_party. The values are not preprocessed in any way other than the "Make" variable substitution.   | String | optional |  `""`  |
| <a id="cc_archive-private_hdrs"></a>private_hdrs |  List of headers that CANNOT be included by dependent rules. Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_archive-public_hdrs"></a>public_hdrs |  List of headers that may be included by dependent rules transitively. Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_archive-reexport_deps"></a>reexport_deps |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_archive-strip_include_prefix"></a>strip_include_prefix |  The prefix to strip from the paths of the headers of this rule. When set, the headers in the hdrs attribute of this rule are accessible at their path with this prefix cut off.<br><br>If it's a relative path, it's taken as a package-relative one. If it's an absolute one, it's understood as a repository-relative path.<br><br>The prefix in the include_prefix attribute is added after this prefix is stripped.   | String | optional |  `""`  |


<a id="cc_bin"></a>

## cc_bin

<pre>
load("@rules_cc_hdrs_map//cc_hdrs_map:defs.bzl", "cc_bin")

cc_bin(<a href="#cc_bin-name">name</a>, <a href="#cc_bin-deps">deps</a>, <a href="#cc_bin-srcs">srcs</a>, <a href="#cc_bin-data">data</a>, <a href="#cc_bin-additional_linker_inputs">additional_linker_inputs</a>, <a href="#cc_bin-conlyopts">conlyopts</a>, <a href="#cc_bin-copts">copts</a>, <a href="#cc_bin-cxxopts">cxxopts</a>, <a href="#cc_bin-defines">defines</a>,
       <a href="#cc_bin-dynamic_deps">dynamic_deps</a>, <a href="#cc_bin-hdrs_map">hdrs_map</a>, <a href="#cc_bin-includes">includes</a>, <a href="#cc_bin-link_extra_lib">link_extra_lib</a>, <a href="#cc_bin-linkopts">linkopts</a>, <a href="#cc_bin-linkstatic">linkstatic</a>, <a href="#cc_bin-local_defines">local_defines</a>, <a href="#cc_bin-malloc">malloc</a>,
       <a href="#cc_bin-nocopts">nocopts</a>, <a href="#cc_bin-private_hdrs">private_hdrs</a>, <a href="#cc_bin-public_hdrs">public_hdrs</a>, <a href="#cc_bin-reexport_deps">reexport_deps</a>, <a href="#cc_bin-stamp">stamp</a>)
</pre>

Produce exectuable binary.

It is intended for this rule, to differ from rules_cc's `cc_binary` in the following
fashion: it aims to automatically gather all of its dynamic dependencies and make them
available during binary execution.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_bin-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cc_bin-deps"></a>deps |  The list of dependencies of current target   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_bin-srcs"></a>srcs |  The list of source files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="cc_bin-data"></a>data |  The list of files needed by this library at runtime. See general comments about data at Typical attributes defined by most build rules.<br><br>If a data is the name of a generated file, then this cc_library rule automatically depends on the generating rule.<br><br>If a data is a rule name, then this cc_library rule automatically depends on that rule, and that rule's outs are automatically added to this cc_library's data files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_bin-additional_linker_inputs"></a>additional_linker_inputs |  Pass these files to the C++ linker command.<br><br>For example, compiled Windows .res files can be provided here to be embedded in the binary target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_bin-conlyopts"></a>conlyopts |  Add these options to the C compilation command. Subject to "Make variable" substitution and Bourne shell tokenization.   | List of strings | optional |  `[]`  |
| <a id="cc_bin-copts"></a>copts |  Add these options to the C++ compilation command. Subject to "Make variable" substitution and Bourne shell tokenization. Each string in this attribute is added in the given order to COPTS before compiling the binary target. The flags take effect only for compiling this target, not its dependencies, so be careful about header files included elsewhere. All paths should be relative to the workspace, not to the current package.<br><br>If the package declares the feature no_copts_tokenization, Bourne shell tokenization applies only to strings that consist of a single "Make" variable.   | List of strings | optional |  `[]`  |
| <a id="cc_bin-cxxopts"></a>cxxopts |  Add these options to the C++ compilation command. Subject to "Make variable" substitution and Bourne shell tokenization.   | List of strings | optional |  `[]`  |
| <a id="cc_bin-defines"></a>defines |  List of defines to add to the compile line. Subject to "Make" variable substitution and Bourne shell tokenization. Each string, which must consist of a single Bourne shell token, is prepended with -D and added to the compile command line to this target, as well as to every rule that depends on it. Be very careful, since this may have far-reaching effects. When in doubt, add define values to local_defines instead.   | List of strings | optional |  `[]`  |
| <a id="cc_bin-dynamic_deps"></a>dynamic_deps |  These are other cc_shared_library dependencies the current target depends on.<br><br>The cc_shared_library implementation will use the list of dynamic_deps (transitively, i.e. also the dynamic_deps of the current target's dynamic_deps) to decide which cc_libraries in the transitive deps should not be linked in because they are already provided by a different cc_shared_library.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_bin-hdrs_map"></a>hdrs_map |  Dictionary describing paths under which header files should be avaiable as.<br><br>Keys are simple glob pathnames, used to match agains all header files avaiable in the rule. Values are list of paths to which matching header files should be mapped.<br><br>'{filename}' is special token used to signify to matching file name.<br><br>For example: '"**/*o.hpp": ["a/{filename}"]' - will ensure all hpp files with names ending with '0' will be also avaible as if they were placed in a subdirectory.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional |  `{}`  |
| <a id="cc_bin-includes"></a>includes |  List of include dirs to be added to the compile line. Subject to "Make variable" substitution. Each string is prepended with -isystem and added to COPTS. Unlike COPTS, these flags are added for this rule and every rule that depends on it. (Note: not the rules it depends upon!) Be very careful, since this may have far-reaching effects. When in doubt, add "-I" flags to COPTS instead.<br><br>Headers must be added to srcs or hdrs, otherwise they will not be available to dependent rules when compilation is sandboxed (the default).   | List of strings | optional |  `[]`  |
| <a id="cc_bin-link_extra_lib"></a>link_extra_lib |  Control linking of extra libraries.<br><br>By default, C++ binaries are linked against //tools/cpp:link_extra_lib, which by default depends on the label flag //tools/cpp:link_extra_libs. Without setting the flag, this library is empty by default. Setting the label flag allows linking optional dependencies, such as overrides for weak symbols, interceptors for shared library functions, or special runtime libraries (for malloc replacements, prefer malloc or --custom_malloc). Setting this attribute to None disables this behaviour.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@bazel_tools//tools/cpp:link_extra_lib"`  |
| <a id="cc_bin-linkopts"></a>linkopts |  Add these flags to the C++ linker command. Subject to "Make" variable substitution, Bourne shell tokenization and label expansion. Each string in this attribute is added to LINKOPTS before linking the binary target. Each element of this list that does not start with $ or - is assumed to be the label of a target in deps. The list of files generated by that target is appended to the linker options. An error is reported if the label is invalid, or is not declared in deps.   | List of strings | optional |  `[]`  |
| <a id="cc_bin-linkstatic"></a>linkstatic |  Link the binary in static mode.   | Boolean | optional |  `True`  |
| <a id="cc_bin-local_defines"></a>local_defines |  List of defines to add to the compile line. Subject to "Make" variable substitution and Bourne shell tokenization. Each string, which must consist of a single Bourne shell token, is prepended with -D and added to the compile command line for this target, but not to its dependents.   | List of strings | optional |  `[]`  |
| <a id="cc_bin-malloc"></a>malloc |  Override the default dependency on malloc.<br><br>By default, C++ binaries are linked against //tools/cpp:malloc, which is an empty library so the binary ends up using libc malloc. This label must refer to a cc_library. If compilation is for a non-C++ rule, this option has no effect. The value of this attribute is ignored if linkshared=True is specified.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@bazel_tools//tools/cpp:malloc"`  |
| <a id="cc_bin-nocopts"></a>nocopts |  Remove matching options from the C++ compilation command. Subject to "Make" variable substitution. The value of this attribute is interpreted as a regular expression. Any preexisting COPTS that match this regular expression (including values explicitly specified in the rule's copts attribute) will be removed from COPTS for purposes of compiling this rule. This attribute should not be needed or used outside of third_party. The values are not preprocessed in any way other than the "Make" variable substitution.   | String | optional |  `""`  |
| <a id="cc_bin-private_hdrs"></a>private_hdrs |  List of headers that CANNOT be included by dependent rules. Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_bin-public_hdrs"></a>public_hdrs |  List of headers that may be included by dependent rules transitively. Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_bin-reexport_deps"></a>reexport_deps |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_bin-stamp"></a>stamp |  Whether to encode build information into the binary. Possible values:<br><br>  * stamp = 1: Always stamp the build information into the binary, even in --nostamp builds. This setting should be avoided, since it potentially kills remote caching for the binary and any downstream actions that depend on it.<br><br>  * stamp = 0: Always replace build information by constant values. This gives good build result caching.<br><br>  * stamp = -1: Embedding of build information is controlled by the --[no]stamp flag.<br><br>Stamped binaries are not rebuilt unless their dependencies change.   | Integer | optional |  `-1`  |


<a id="cc_hdrs"></a>

## cc_hdrs

<pre>
load("@rules_cc_hdrs_map//cc_hdrs_map:defs.bzl", "cc_hdrs")

cc_hdrs(<a href="#cc_hdrs-name">name</a>, <a href="#cc_hdrs-deps">deps</a>, <a href="#cc_hdrs-hdrs_map">hdrs_map</a>, <a href="#cc_hdrs-private_hdrs">private_hdrs</a>, <a href="#cc_hdrs-public_hdrs">public_hdrs</a>)
</pre>

Define header files properties.

This rule groups headers into a singular target and allows
to attach 'include_path' modifications information to them,
so that wherever the header files are being used, they can
be used with their intended include paths.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_hdrs-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cc_hdrs-deps"></a>deps |  The list of dependencies of current target   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_hdrs-hdrs_map"></a>hdrs_map |  Dictionary describing paths under which header files should be avaiable as.<br><br>Keys are simple glob pathnames, used to match agains all header files avaiable in the rule. Values are list of paths to which matching header files should be mapped.<br><br>'{filename}' is special token used to signify to matching file name.<br><br>For example: '"**/*o.hpp": ["a/{filename}"]' - will ensure all hpp files with names ending with '0' will be also avaible as if they were placed in a subdirectory.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional |  `{}`  |
| <a id="cc_hdrs-private_hdrs"></a>private_hdrs |  List of headers that CANNOT be included by dependent rules. Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_hdrs-public_hdrs"></a>public_hdrs |  List of headers that may be included by dependent rules transitively. Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |


<a id="cc_so"></a>

## cc_so

<pre>
load("@rules_cc_hdrs_map//cc_hdrs_map:defs.bzl", "cc_so")

cc_so(<a href="#cc_so-name">name</a>, <a href="#cc_so-deps">deps</a>, <a href="#cc_so-srcs">srcs</a>, <a href="#cc_so-additional_linker_inputs">additional_linker_inputs</a>, <a href="#cc_so-alwayslink">alwayslink</a>, <a href="#cc_so-conlyopts">conlyopts</a>, <a href="#cc_so-copts">copts</a>, <a href="#cc_so-cxxopts">cxxopts</a>, <a href="#cc_so-defines">defines</a>,
      <a href="#cc_so-dynamic_deps">dynamic_deps</a>, <a href="#cc_so-hdrs_map">hdrs_map</a>, <a href="#cc_so-include_prefix">include_prefix</a>, <a href="#cc_so-includes">includes</a>, <a href="#cc_so-link_extra_lib">link_extra_lib</a>, <a href="#cc_so-linkopts">linkopts</a>, <a href="#cc_so-linkstatic">linkstatic</a>,
      <a href="#cc_so-local_defines">local_defines</a>, <a href="#cc_so-malloc">malloc</a>, <a href="#cc_so-nocopts">nocopts</a>, <a href="#cc_so-private_hdrs">private_hdrs</a>, <a href="#cc_so-public_hdrs">public_hdrs</a>, <a href="#cc_so-reexport_deps">reexport_deps</a>, <a href="#cc_so-strip_include_prefix">strip_include_prefix</a>)
</pre>

Produce shared object library.

The intended difference between this rule and the rules_cc's cc_shared_library is
to unify handling of dependencies that are equipped with CcInfo and CcSharedLibraryInfo
(use singular attribute of deps to track them both).

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_so-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cc_so-deps"></a>deps |  The list of dependencies of current target   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_so-srcs"></a>srcs |  The list of source files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="cc_so-additional_linker_inputs"></a>additional_linker_inputs |  Pass these files to the C++ linker command.<br><br>For example, compiled Windows .res files can be provided here to be embedded in the binary target.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_so-alwayslink"></a>alwayslink |  If 1, any binary that depends (directly or indirectly) on this C++ library will link in all the object files for the files listed in srcs, even if some contain no symbols referenced by the binary. This is useful if your code isn't explicitly called by code in the binary, e.g., if your code registers to receive some callback provided by some service.   | Boolean | optional |  `True`  |
| <a id="cc_so-conlyopts"></a>conlyopts |  Add these options to the C compilation command. Subject to "Make variable" substitution and Bourne shell tokenization.   | List of strings | optional |  `[]`  |
| <a id="cc_so-copts"></a>copts |  Add these options to the C++ compilation command. Subject to "Make variable" substitution and Bourne shell tokenization. Each string in this attribute is added in the given order to COPTS before compiling the binary target. The flags take effect only for compiling this target, not its dependencies, so be careful about header files included elsewhere. All paths should be relative to the workspace, not to the current package.<br><br>If the package declares the feature no_copts_tokenization, Bourne shell tokenization applies only to strings that consist of a single "Make" variable.   | List of strings | optional |  `[]`  |
| <a id="cc_so-cxxopts"></a>cxxopts |  Add these options to the C++ compilation command. Subject to "Make variable" substitution and Bourne shell tokenization.   | List of strings | optional |  `[]`  |
| <a id="cc_so-defines"></a>defines |  List of defines to add to the compile line. Subject to "Make" variable substitution and Bourne shell tokenization. Each string, which must consist of a single Bourne shell token, is prepended with -D and added to the compile command line to this target, as well as to every rule that depends on it. Be very careful, since this may have far-reaching effects. When in doubt, add define values to local_defines instead.   | List of strings | optional |  `[]`  |
| <a id="cc_so-dynamic_deps"></a>dynamic_deps |  These are other cc_shared_library dependencies the current target depends on.<br><br>The cc_shared_library implementation will use the list of dynamic_deps (transitively, i.e. also the dynamic_deps of the current target's dynamic_deps) to decide which cc_libraries in the transitive deps should not be linked in because they are already provided by a different cc_shared_library.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_so-hdrs_map"></a>hdrs_map |  Dictionary describing paths under which header files should be avaiable as.<br><br>Keys are simple glob pathnames, used to match agains all header files avaiable in the rule. Values are list of paths to which matching header files should be mapped.<br><br>'{filename}' is special token used to signify to matching file name.<br><br>For example: '"**/*o.hpp": ["a/{filename}"]' - will ensure all hpp files with names ending with '0' will be also avaible as if they were placed in a subdirectory.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional |  `{}`  |
| <a id="cc_so-include_prefix"></a>include_prefix |  The prefix to add to the paths of the headers of this rule. When set, the headers in the hdrs attribute of this rule are accessible at is the value of this attribute prepended to their repository-relative path.<br><br>The prefix in the strip_include_prefix attribute is removed before this prefix is added.   | String | optional |  `""`  |
| <a id="cc_so-includes"></a>includes |  List of include dirs to be added to the compile line. Subject to "Make variable" substitution. Each string is prepended with -isystem and added to COPTS. Unlike COPTS, these flags are added for this rule and every rule that depends on it. (Note: not the rules it depends upon!) Be very careful, since this may have far-reaching effects. When in doubt, add "-I" flags to COPTS instead.<br><br>Headers must be added to srcs or hdrs, otherwise they will not be available to dependent rules when compilation is sandboxed (the default).   | List of strings | optional |  `[]`  |
| <a id="cc_so-link_extra_lib"></a>link_extra_lib |  Control linking of extra libraries.<br><br>By default, C++ binaries are linked against //tools/cpp:link_extra_lib, which by default depends on the label flag //tools/cpp:link_extra_libs. Without setting the flag, this library is empty by default. Setting the label flag allows linking optional dependencies, such as overrides for weak symbols, interceptors for shared library functions, or special runtime libraries (for malloc replacements, prefer malloc or --custom_malloc). Setting this attribute to None disables this behaviour.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@bazel_tools//tools/cpp:link_extra_lib"`  |
| <a id="cc_so-linkopts"></a>linkopts |  Add these flags to the C++ linker command. Subject to "Make" variable substitution, Bourne shell tokenization and label expansion. Each string in this attribute is added to LINKOPTS before linking the binary target. Each element of this list that does not start with $ or - is assumed to be the label of a target in deps. The list of files generated by that target is appended to the linker options. An error is reported if the label is invalid, or is not declared in deps.   | List of strings | optional |  `[]`  |
| <a id="cc_so-linkstatic"></a>linkstatic |  Link the binary in static mode.   | Boolean | optional |  `True`  |
| <a id="cc_so-local_defines"></a>local_defines |  List of defines to add to the compile line. Subject to "Make" variable substitution and Bourne shell tokenization. Each string, which must consist of a single Bourne shell token, is prepended with -D and added to the compile command line for this target, but not to its dependents.   | List of strings | optional |  `[]`  |
| <a id="cc_so-malloc"></a>malloc |  Override the default dependency on malloc.<br><br>By default, C++ binaries are linked against //tools/cpp:malloc, which is an empty library so the binary ends up using libc malloc. This label must refer to a cc_library. If compilation is for a non-C++ rule, this option has no effect. The value of this attribute is ignored if linkshared=True is specified.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `"@bazel_tools//tools/cpp:malloc"`  |
| <a id="cc_so-nocopts"></a>nocopts |  Remove matching options from the C++ compilation command. Subject to "Make" variable substitution. The value of this attribute is interpreted as a regular expression. Any preexisting COPTS that match this regular expression (including values explicitly specified in the rule's copts attribute) will be removed from COPTS for purposes of compiling this rule. This attribute should not be needed or used outside of third_party. The values are not preprocessed in any way other than the "Make" variable substitution.   | String | optional |  `""`  |
| <a id="cc_so-private_hdrs"></a>private_hdrs |  List of headers that CANNOT be included by dependent rules. Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_so-public_hdrs"></a>public_hdrs |  List of headers that may be included by dependent rules transitively. Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_so-reexport_deps"></a>reexport_deps |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="cc_so-strip_include_prefix"></a>strip_include_prefix |  The prefix to strip from the paths of the headers of this rule. When set, the headers in the hdrs attribute of this rule are accessible at their path with this prefix cut off.<br><br>If it's a relative path, it's taken as a package-relative one. If it's an absolute one, it's understood as a repository-relative path.<br><br>The prefix in the include_prefix attribute is added after this prefix is stripped.   | String | optional |  `""`  |


<a id="HdrsMapInfo"></a>

## HdrsMapInfo

<pre>
load("@rules_cc_hdrs_map//cc_hdrs_map:defs.bzl", "HdrsMapInfo")

HdrsMapInfo(<a href="#HdrsMapInfo-public_hdrs">public_hdrs</a>, <a href="#HdrsMapInfo-private_hdrs">private_hdrs</a>, <a href="#HdrsMapInfo-hdrs_map">hdrs_map</a>, <a href="#HdrsMapInfo-deps">deps</a>)
</pre>

Represents grouping of CC header files, alongsdie with their intended include paths.

**FIELDS**

| Name  | Description |
| :------------- | :------------- |
| <a id="HdrsMapInfo-public_hdrs"></a>public_hdrs |  Headers which should be exposed after the compilation is done.    |
| <a id="HdrsMapInfo-private_hdrs"></a>private_hdrs |  Headers that should not be propagated after the compilation.    |
| <a id="HdrsMapInfo-hdrs_map"></a>hdrs_map |  (string_list_dict) which represents mapping between pattern and its intended include paths (i.e. "**/foo.hpp": ["bar/{filename}"])    |
| <a id="HdrsMapInfo-deps"></a>deps |  CcInfo-aware dependencies that need to be propagated, for this provider to compile and link    |


<a id="actions.compile_kwargs"></a>

## actions.compile_kwargs

<pre>
load("@rules_cc_hdrs_map//cc_hdrs_map:defs.bzl", "actions")

actions.compile_kwargs(<a href="#actions.compile_kwargs-ctx">ctx</a>, <a href="#actions.compile_kwargs-rule_attrs">rule_attrs</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="actions.compile_kwargs-ctx"></a>ctx |  <p align="center"> - </p>   |  none |
| <a id="actions.compile_kwargs-rule_attrs"></a>rule_attrs |  <p align="center"> - </p>   |  none |


<a id="actions.link_to_archive_kwargs"></a>

## actions.link_to_archive_kwargs

<pre>
load("@rules_cc_hdrs_map//cc_hdrs_map:defs.bzl", "actions")

actions.link_to_archive_kwargs(<a href="#actions.link_to_archive_kwargs-ctx">ctx</a>, <a href="#actions.link_to_archive_kwargs-rule_attrs">rule_attrs</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="actions.link_to_archive_kwargs-ctx"></a>ctx |  <p align="center"> - </p>   |  none |
| <a id="actions.link_to_archive_kwargs-rule_attrs"></a>rule_attrs |  <p align="center"> - </p>   |  none |


<a id="actions.link_to_binary_kwargs"></a>

## actions.link_to_binary_kwargs

<pre>
load("@rules_cc_hdrs_map//cc_hdrs_map:defs.bzl", "actions")

actions.link_to_binary_kwargs(<a href="#actions.link_to_binary_kwargs-ctx">ctx</a>, <a href="#actions.link_to_binary_kwargs-rule_attrs">rule_attrs</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="actions.link_to_binary_kwargs-ctx"></a>ctx |  <p align="center"> - </p>   |  none |
| <a id="actions.link_to_binary_kwargs-rule_attrs"></a>rule_attrs |  <p align="center"> - </p>   |  none |


<a id="actions.link_to_so_kwargs"></a>

## actions.link_to_so_kwargs

<pre>
load("@rules_cc_hdrs_map//cc_hdrs_map:defs.bzl", "actions")

actions.link_to_so_kwargs(<a href="#actions.link_to_so_kwargs-ctx">ctx</a>, <a href="#actions.link_to_so_kwargs-rule_attrs">rule_attrs</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="actions.link_to_so_kwargs-ctx"></a>ctx |  <p align="center"> - </p>   |  none |
| <a id="actions.link_to_so_kwargs-rule_attrs"></a>rule_attrs |  <p align="center"> - </p>   |  none |


