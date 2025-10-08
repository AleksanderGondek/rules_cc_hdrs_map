""" This module defines the CC compilation phase actions which are exposed publicalyl as subrules. """

load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain")
load(":cc_helper.bzl", _cc_helper = "cc_helper")
load(":compile.bzl", _compile = "compile")
load(":link_to_archive.bzl", _link_to_archive = "link_to_archive")
load(":link_to_binary.bzl", _link_to_binary = "link_to_binary")
load(":link_to_so.bzl", _link_to_so = "link_to_so")

def _attrs_into_action_kwargs(ctx, rule_attrs, action_name):
    # Bazel subrules are not allowed to call 'expand_location' (error will be thrown), nor
    # supposed to touch ctx.var nor ctx.attr.data [1].
    # This puts the make variables expansion logic in precarious position, in which
    # it cannot truly happen within subrule (unless the logic is completely re-written from scratch in starlark).
    # Currently it is supposed to happen on the rule-level - however the resolved toolchain, should
    # not be passed into subrules, as they - theoreticaly - do their own thing.
    # Therfore this ugly solution - toolchain and configuration features (required for expansion for legacy reasons),
    # are found and provided in the rule-level expansiion phase and are then dropped.
    # [1] https://docs.google.com/document/d/1RbNC88QieKvBEwir7iV5zZU08AaMlOzxhVkPnmKDedQ/edit?disco=AAAAzp_Oj3g
    _cc_toolchain = find_cc_toolchain(ctx)
    _rule_level_cc_info = struct(
        cc_toolchain = _cc_toolchain,
        cc_feature_configuration = cc_common.configure_features(
            ctx = ctx,
            cc_toolchain = _cc_toolchain,
            requested_features = ctx.features,
            unsupported_features = ctx.disabled_features,
        ),
    )

    action_kwargs = {
        "cc_feature_configuration_func": lambda cc_toolchain, features = [], disabled_features = []: cc_common.configure_features(
            ctx = ctx,
            cc_toolchain = cc_toolchain,
            # Not copying the ctx.feature to allow for potential sheneningans within action
            requested_features = features,
            unsupported_features = disabled_features,
        ),
        "features": ctx.features,
        "disabled_features": ctx.disabled_features,
    }

    expand_make_variables_funcs_to_call = []
    for _, attr_meta in rule_attrs.items():
        kwarg_meta = getattr(attr_meta.as_action_param, action_name)(ctx.attr)
        if not kwarg_meta:
            continue

        # Remember make variables expansions to call afterwards
        expand_make_variables_func = getattr(attr_meta, "expand_make_variables", None)
        if expand_make_variables_func:
            expand_make_variables_funcs_to_call.append(expand_make_variables_func)

        if type(kwarg_meta[1]) == "list":
            compile_kwarg = action_kwargs.setdefault(kwarg_meta[0], [])
            for kwarg in kwarg_meta[1]:
                compile_kwarg.append(kwarg)

            # TODO: Handling of a dictionaries merge
        else:
            action_kwargs[kwarg_meta[0]] = kwarg_meta[1]

        for expand_make_variables_func in expand_make_variables_funcs_to_call:
            # This ensure the make variable expansion happens at the rule-level, not subrule-level
            transformed_kwarg = expand_make_variables_func(ctx, _rule_level_cc_info, dict(action_kwargs))
            action_kwargs[transformed_kwarg[0]] = transformed_kwarg[1]

    return action_kwargs

actions = struct(
    compile = _compile,
    compile_kwargs = lambda ctx, rule_attrs: _attrs_into_action_kwargs(ctx, rule_attrs, "compile"),
    link_to_archive = _link_to_archive,
    link_to_archive_kwargs = lambda ctx, rule_attrs: _attrs_into_action_kwargs(ctx, rule_attrs, "link_to_archive"),
    link_to_binary = _link_to_binary,
    link_to_binary_kwargs = lambda ctx, rule_attrs: _attrs_into_action_kwargs(ctx, rule_attrs, "link_to_bin"),
    link_to_so = _link_to_so,
    link_to_so_kwargs = lambda ctx, rule_attrs: _attrs_into_action_kwargs(ctx, rule_attrs, "link_to_so"),
    prepare_for_compilation = _cc_helper.prepare_for_compilation,
)
