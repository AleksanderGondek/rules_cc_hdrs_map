""" This module exposes a way to load rule dependencies in non-bzlmod usage. """

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def cc_hdrs_map_workspace_deps():
    """Load all dependencies of cc_hdrs_map."""
    maybe(
        http_archive,
        name = "rules_cc",
        sha256 = "64cb81641305dcf7b3b3d5a73095ee8fe7444b26f7b72a12227d36e15cfbb6cb",
        strip_prefix = "rules_cc-0.1.3",
        url = "https://github.com/bazelbuild/rules_cc/releases/download/0.1.3/rules_cc-0.1.3.tar.gz",
    )
