rules_cc_hdrs_map
---
![CI status](https://github.com/AleksanderGondek/rules_cc_hdrs_map/actions/workflows/ci.yaml/badge.svg) [![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

This project extends Bazel C/CPP build capabilities with headers map implementation. 

## What issue is being addressed?

Scenario: we want to build a C/CPP codebase with Bazel. 

One of its key characteristics is that most of the include statements __do not reflect the code structure__ in the project - for example, header file located under path "_name/a.hpp_" is never included as "_name/a.hpp_", instead an arbitrary list of aliases is used in the code ("_x/y/z/a.hpp_", "_b.hpp_" etc.).  There is no over-arching convention that could be used to generalize those statements into another file file hierarchy - in other words, every header file is a special case of its own.

Unfortunately we are __forbidden from modifying__ the code itself and the directory structure (hello from enterprise word). 

As Bazel `rules_cc` have the expectation of header files being included in a way that resembles the file structure in the WORKSPACE (and one can only provide single “_include prefix_” per library), we need to prepare the “expected file structure” before passing them into the `rules_cc`.

In the most naive approach, said “_expected file structure_” is being prepared for each compilable target, passing on the already created structure to targets that the bend on it. Very quickly conflicts occur and change of a single header file may cascade into rebuild of hundreds of targets. 

There has to be a better way!

## How the issue is being addressed? 
