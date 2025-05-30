""" This module exposes a way to load rule dependencies in non-bzlmod usage. """

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def cc_hdrs_map_workspace_deps():
    """Load all dependencies of cc_hdrs_map."""
    maybe(
        http_archive,
        name = "rules_cc",
        urls = ["https://github.com/bazelbuild/rules_cc/releases/download/0.1.1/rules_cc-0.1.1.tar.gz"],
        sha256 = "712d77868b3152dd618c4d64faaddefcc5965f90f5de6e6dd1d5ddcd0be82d42",
        strip_prefix = "rules_cc-0.1.1",
    )
