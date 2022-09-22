<!-- Generated with Stardoc: http://skydoc.bazel.build -->

 To be described. 

<a id="cc_static"></a>

## cc_static

<pre>
cc_static(<a href="#cc_static-name">name</a>, <a href="#cc_static-additional_linker_inputs">additional_linker_inputs</a>, <a href="#cc_static-copts">copts</a>, <a href="#cc_static-defines">defines</a>, <a href="#cc_static-deps">deps</a>, <a href="#cc_static-hdrs_map">hdrs_map</a>, <a href="#cc_static-include_prefix">include_prefix</a>, <a href="#cc_static-includes">includes</a>,
          <a href="#cc_static-linkopts">linkopts</a>, <a href="#cc_static-linkstatic">linkstatic</a>, <a href="#cc_static-local_defines">local_defines</a>, <a href="#cc_static-private_hdrs">private_hdrs</a>, <a href="#cc_static-public_hdrs">public_hdrs</a>, <a href="#cc_static-srcs">srcs</a>, <a href="#cc_static-strip_include_prefix">strip_include_prefix</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_static-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cc_static-additional_linker_inputs"></a>additional_linker_inputs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_static-copts"></a>copts |  -   | List of strings | optional | [] |
| <a id="cc_static-defines"></a>defines |  -   | List of strings | optional | [] |
| <a id="cc_static-deps"></a>deps |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_static-hdrs_map"></a>hdrs_map |  -   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional | {} |
| <a id="cc_static-include_prefix"></a>include_prefix |  -   | String | optional | "" |
| <a id="cc_static-includes"></a>includes |  -   | List of strings | optional | [] |
| <a id="cc_static-linkopts"></a>linkopts |  -   | List of strings | optional | [] |
| <a id="cc_static-linkstatic"></a>linkstatic |  -   | Boolean | optional | True |
| <a id="cc_static-local_defines"></a>local_defines |  -   | List of strings | optional | [] |
| <a id="cc_static-private_hdrs"></a>private_hdrs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_static-public_hdrs"></a>public_hdrs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_static-srcs"></a>srcs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="cc_static-strip_include_prefix"></a>strip_include_prefix |  -   | String | optional | "" |


