""" This module defines the CC compilation phase actions which are exposed publicalyl as subrules. """

load(":compile.bzl", _compile = "compile")
load(":link_to_archive.bzl", _link_to_archive = "link_to_archive")
load(":link_to_binary.bzl", _link_to_binary = "link_to_binary")
load(":link_to_so.bzl", _link_to_so = "link_to_so")

def _attrs_into_action_kwargs(ctx, rule_attrs, action_name):
    compile_kwargs = {
        "configure_features_func": lambda cc_toolchain, features = [], disabled_features = []: cc_common.configure_features(
            ctx = ctx,
            cc_toolchain = cc_toolchain,
            # Not copying the ctx.feature to allow for potential sheneningans within action
            requested_features = features,
            unsupported_features = disabled_features,
        ),
        "features": ctx.features,
        "disabled_features": ctx.disabled_features,
    }
    for _, attr_meta in rule_attrs.items():
        kwarg_meta = getattr(attr_meta.as_action_param, action_name)(ctx.attr)
        if not kwarg_meta:
            continue

        if type(kwarg_meta[1]) == "list":
            compile_kwarg = compile_kwargs.setdefault(kwarg_meta[0], [])
            for kwarg in kwarg_meta[1]:
                if kwarg in compile_kwarg:
                    continue
                compile_kwarg.append(kwarg)

            # TODO: Handling of a dictionaries merge
        else:
            compile_kwargs[kwarg_meta[0]] = kwarg_meta[1]

    return compile_kwargs

actions = struct(
    compile = _compile,
    compile_kwargs = lambda ctx, rule_attrs: _attrs_into_action_kwargs(ctx, rule_attrs, "compile"),
    link_to_archive = _link_to_archive,
    link_to_archive_kwargs = lambda ctx, rule_attrs: _attrs_into_action_kwargs(ctx, rule_attrs, "link_to_archive"),
    link_to_binary = _link_to_binary,
    link_to_binary_kwargs = lambda ctx, rule_attrs: _attrs_into_action_kwargs(ctx, rule_attrs, "link_to_bin"),
    link_to_so = _link_to_so,
    link_to_so_kwargs = lambda ctx, rule_attrs: _attrs_into_action_kwargs(ctx, rule_attrs, "link_to_so"),
)
