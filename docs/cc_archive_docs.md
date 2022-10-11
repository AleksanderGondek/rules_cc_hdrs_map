<!-- Generated with Stardoc: http://skydoc.bazel.build -->

 To be described. 

<a id="cc_archive"></a>

## cc_archive

<pre>
cc_archive(<a href="#cc_archive-name">name</a>, <a href="#cc_archive-additional_linker_inputs">additional_linker_inputs</a>, <a href="#cc_archive-copts">copts</a>, <a href="#cc_archive-defines">defines</a>, <a href="#cc_archive-deps">deps</a>, <a href="#cc_archive-hdrs_map">hdrs_map</a>, <a href="#cc_archive-include_prefix">include_prefix</a>, <a href="#cc_archive-includes">includes</a>,
           <a href="#cc_archive-linkopts">linkopts</a>, <a href="#cc_archive-linkstatic">linkstatic</a>, <a href="#cc_archive-local_defines">local_defines</a>, <a href="#cc_archive-private_hdrs">private_hdrs</a>, <a href="#cc_archive-public_hdrs">public_hdrs</a>, <a href="#cc_archive-srcs">srcs</a>, <a href="#cc_archive-strip_include_prefix">strip_include_prefix</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_archive-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cc_archive-additional_linker_inputs"></a>additional_linker_inputs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_archive-copts"></a>copts |  -   | List of strings | optional | [] |
| <a id="cc_archive-defines"></a>defines |  -   | List of strings | optional | [] |
| <a id="cc_archive-deps"></a>deps |  The list of dependencies of current target   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_archive-hdrs_map"></a>hdrs_map |  Dictionary describing paths under which header files should be avaiable as.<br><br>        Keys are simple glob pathnames, used to match agains all header files avaiable in the rule.         Values are list of paths to which matching header files should be mapped.<br><br>        '{filename}' is special token used to signify to matching file name.<br><br>        For example:         '"**/*o.hpp": ["a/{filename}"]' - will ensure all hpp files with names ending with '0'         will be also avaible as if they were placed in a subdirectory.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional | {} |
| <a id="cc_archive-include_prefix"></a>include_prefix |  -   | String | optional | "" |
| <a id="cc_archive-includes"></a>includes |  -   | List of strings | optional | [] |
| <a id="cc_archive-linkopts"></a>linkopts |  -   | List of strings | optional | [] |
| <a id="cc_archive-linkstatic"></a>linkstatic |  -   | Boolean | optional | True |
| <a id="cc_archive-local_defines"></a>local_defines |  -   | List of strings | optional | [] |
| <a id="cc_archive-private_hdrs"></a>private_hdrs |  List of headers that CANNOT be included by dependent rules.         Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_archive-public_hdrs"></a>public_hdrs |  List of headers that may be included by dependent rules transitively.         Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_archive-srcs"></a>srcs |  The list of source files.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="cc_archive-strip_include_prefix"></a>strip_include_prefix |  -   | String | optional | "" |


