<!-- Generated with Stardoc: http://skydoc.bazel.build -->

 Module providing means of enriching header file groups with mapping metadata. 

<a id="cc_hdrs"></a>

## cc_hdrs

<pre>
cc_hdrs(<a href="#cc_hdrs-name">name</a>, <a href="#cc_hdrs-deps">deps</a>, <a href="#cc_hdrs-hdrs_map">hdrs_map</a>, <a href="#cc_hdrs-private_hdrs">private_hdrs</a>, <a href="#cc_hdrs-public_hdrs">public_hdrs</a>)
</pre>


This rule allows for grouping header files as a unit and 
equipping them with a headers map. Thanks to this approach, 
information about expected include paths may be kept close
to the header files themselve, instead of being repeated 
in multiple compilation targets. 

Example:
```python
cc_hdrs(
    name = "foo_hdrs",
    hdrs_map = {
        "**/*.hpp": ["bar/{filename}"],
    },
    public_hdrs = [
        "foo.hpp",
    ],
)
```


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cc_hdrs-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cc_hdrs-deps"></a>deps |  The list of dependencies of current target   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_hdrs-hdrs_map"></a>hdrs_map |  Dictionary describing paths under which header files should be avaiable as.<br><br>        Keys are simple glob pathnames, used to match agains all header files avaiable in the rule.         Values are list of paths to which matching header files should be mapped.<br><br>        '{filename}' is special token used to signify to matching file name.<br><br>        For example:         '"**/*o.hpp": ["a/{filename}"]' - will ensure all hpp files with names ending with '0'         will be also avaible as if they were placed in a subdirectory.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> List of strings</a> | optional | {} |
| <a id="cc_hdrs-private_hdrs"></a>private_hdrs |  List of headers that CANNOT be included by dependent rules.         Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |
| <a id="cc_hdrs-public_hdrs"></a>public_hdrs |  List of headers that may be included by dependent rules transitively.         Notice: the cutoff happens during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | [] |


