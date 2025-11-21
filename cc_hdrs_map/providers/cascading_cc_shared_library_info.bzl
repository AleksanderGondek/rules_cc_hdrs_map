"""This module contains function that help with dealing with CcSharedLibraryInfo provider."""

load("@rules_cc//cc/common:cc_shared_library_info.bzl", "CcSharedLibraryInfo")

CascadingCcSharedLibraryInfo = provider(
    doc = "Represents CcSharedLibrary that should cascade and be link in every transitive dependee.",
    fields = {
        "cc_shared_library_infos": "[] of CcSharedLibraryInfo providers that describes what needs to be cascaded.",
    },
)
