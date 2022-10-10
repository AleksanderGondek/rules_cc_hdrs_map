rules_cc_hdrs_map
---
![CI status](https://github.com/AleksanderGondek/rules_cc_hdrs_map/actions/workflows/ci.yaml/badge.svg) [![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

This project extends Bazel C/CPP build capabilities with headers map implementation. 

## What issue is being addressed?

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

