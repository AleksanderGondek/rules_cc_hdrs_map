<!-- Generated with Stardoc: http://skydoc.bazel.build -->

 To be described. 

<a id="cc_so"></a>

## cc_so

<pre>
cc_so(<a href="#cc_so-name">name</a>, <a href="#cc_so-additional_linker_inputs">additional_linker_inputs</a>, <a href="#cc_so-alwayslink">alwayslink</a>, <a href="#cc_so-copts">copts</a>, <a href="#cc_so-defines">defines</a>, <a href="#cc_so-deps">deps</a>, <a href="#cc_so-hdrs_map">hdrs_map</a>, <a href="#cc_so-include_prefix">include_prefix</a>,
      <a href="#cc_so-includes">includes</a>, <a href="#cc_so-linkopts">linkopts</a>, <a href="#cc_so-linkstatic">linkstatic</a>, <a href="#cc_so-local_defines">local_defines</a>, <a href="#cc_so-private_hdrs">private_hdrs</a>, <a href="#cc_so-public_hdrs">public_hdrs</a>, <a href="#cc_so-srcs">srcs</a>,
      <a href="#cc_so-strip_include_prefix">strip_include_prefix</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_so-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cc_so-additional_linker_inputs"></a>additional_linker_inputs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_so-alwayslink"></a>alwayslink |  -   | Boolean | optional | True |
| <a id="cc_so-copts"></a>copts |  -   | List of strings | optional | [] |
| <a id="cc_so-defines"></a>defines |  -   | List of strings | optional | [] |
| <a id="cc_so-deps"></a>deps |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_so-hdrs_map"></a>hdrs_map |  -   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional | {} |
| <a id="cc_so-include_prefix"></a>include_prefix |  -   | String | optional | "" |
| <a id="cc_so-includes"></a>includes |  -   | List of strings | optional | [] |
| <a id="cc_so-linkopts"></a>linkopts |  -   | List of strings | optional | [] |
| <a id="cc_so-linkstatic"></a>linkstatic |  -   | Boolean | optional | True |
| <a id="cc_so-local_defines"></a>local_defines |  -   | List of strings | optional | [] |
| <a id="cc_so-private_hdrs"></a>private_hdrs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_so-public_hdrs"></a>public_hdrs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_so-srcs"></a>srcs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="cc_so-strip_include_prefix"></a>strip_include_prefix |  -   | String | optional | "" |


