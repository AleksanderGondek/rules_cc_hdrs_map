<!-- Generated with Stardoc: http://skydoc.bazel.build -->

 To be described. 

<a id="cc_bin"></a>

## cc_bin

<pre>
cc_bin(<a href="#cc_bin-name">name</a>, <a href="#cc_bin-additional_linker_inputs">additional_linker_inputs</a>, <a href="#cc_bin-copts">copts</a>, <a href="#cc_bin-defines">defines</a>, <a href="#cc_bin-deps">deps</a>, <a href="#cc_bin-hdrs_map">hdrs_map</a>, <a href="#cc_bin-includes">includes</a>, <a href="#cc_bin-linkopts">linkopts</a>,
       <a href="#cc_bin-linkstatic">linkstatic</a>, <a href="#cc_bin-local_defines">local_defines</a>, <a href="#cc_bin-private_hdrs">private_hdrs</a>, <a href="#cc_bin-public_hdrs">public_hdrs</a>, <a href="#cc_bin-srcs">srcs</a>, <a href="#cc_bin-stamp">stamp</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_bin-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cc_bin-additional_linker_inputs"></a>additional_linker_inputs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_bin-copts"></a>copts |  -   | List of strings | optional | [] |
| <a id="cc_bin-defines"></a>defines |  -   | List of strings | optional | [] |
| <a id="cc_bin-deps"></a>deps |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_bin-hdrs_map"></a>hdrs_map |  -   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional | {} |
| <a id="cc_bin-includes"></a>includes |  -   | List of strings | optional | [] |
| <a id="cc_bin-linkopts"></a>linkopts |  -   | List of strings | optional | [] |
| <a id="cc_bin-linkstatic"></a>linkstatic |  -   | Boolean | optional | True |
| <a id="cc_bin-local_defines"></a>local_defines |  -   | List of strings | optional | [] |
| <a id="cc_bin-private_hdrs"></a>private_hdrs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_bin-public_hdrs"></a>public_hdrs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_bin-srcs"></a>srcs |  -   | <a href="https://bazel.build/concepts/labels">List of labels</a> | required |  |
| <a id="cc_bin-stamp"></a>stamp |  -   | Integer | optional | -1 |


