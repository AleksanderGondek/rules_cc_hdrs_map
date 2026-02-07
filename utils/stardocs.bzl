"""
Utility macros for generating markdown documentation.

The logic was previously present in the {aspect-}bazel-lib but was
removed (https://github.com/bazel-contrib/bazel-lib/issues/1185).

The current implementation is heavily inspired by said logic
(https://github.com/bazel-contrib/bazel-lib/blob/cbdd3a88650b8708c89c6871c07a5fcf01a89bc0/lib/private/docs.bzl)
but was modified to not use `native.` functionality.
"""

load("@bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@stardoc//stardoc:stardoc.bzl", _stardoc = "stardoc")

def stardoc_with_diff_test(name, bzl_library_target, **kwargs):
    """Creates a stardoc target and update_docs target which writes the generated doc to the source tree and tests that it's up to date.

    This is helpful for minimizing boilerplate in repos with lots of stardoc targets.

    Args:
        name: the name of the stardoc file to be written to the current source directory (.md will be appended to the name). Call bazel run on this target to update the file.
        bzl_library_target: the label of the `bzl_library` target to generate documentation for
        **kwargs: additional attributes passed to the stardoc() rule, such as for overriding the templates
    """

    _stardoc(
        name = name,
        out = "{}-docgen.md".format(name),
        input = "{}.bzl".format(bzl_library_target),
        deps = [bzl_library_target],
        **kwargs
    )

    write_source_files(
        name = "{}.update".format(name),
        files = {
            "{}.md".format(name): ":{}-docgen.md".format(name),
        },
    )
