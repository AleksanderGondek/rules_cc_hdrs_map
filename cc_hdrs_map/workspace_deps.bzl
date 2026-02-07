""" This module exposes a way to load rule dependencies in non-bzlmod usage. """

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def cc_hdrs_map_workspace_deps():
    """Load all dependencies of cc_hdrs_map."""
    maybe(
        http_archive,
        name = "rules_cc",
        sha256 = "458b658277ba51b4730ea7a2020efdf1c6dcadf7d30de72e37f4308277fa8c01",
        strip_prefix = "rules_cc-0.2.16",
        url = "https://github.com/bazelbuild/rules_cc/releases/download/0.2.16/rules_cc-0.2.16.tar.gz",
    )
