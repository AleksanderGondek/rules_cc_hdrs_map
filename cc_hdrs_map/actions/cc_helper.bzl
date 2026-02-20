""" This module serves chiefly as a vehicle for exposing 'private' cc_helper methods to current rule set. """

load("@rules_cc//cc:defs.bzl", "cc_common")
load("@rules_cc//cc/common:cc_helper.bzl", rules_cc_extensions = "extensions", rules_cc_helper = "cc_helper")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl", "materialize_hdrs_mapping", "new_hdrs_map")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map_info.bzl", "HdrsMapInfo", "quotient_map_hdrs_map_infos")

_EXTENSIONS = struct(
    cc_header = lambda: rules_cc_extensions.CC_HEADER,
    cc_source = lambda: (
        rules_cc_extensions.C_SOURCE +
        rules_cc_extensions.CC_SOURCE +
        rules_cc_extensions.ASSEMBLER +
        rules_cc_extensions.ASSEMBLER_WITH_C_PREPROCESSOR +
        [".i", ".ii"]  # pre-processed files
    ),
)

# Author soap box:
# I do not understand the obsession with making everything private,
# especially that Starlark is based on Python.
# Here it is making things more convoluted, because there is no easy
# way I can extract 'private' methods from rules_cc's cc_helper.
# The result is a copypaste.

# === COPYPASTE BEIGNS ===
# === Synced to v0.2.16

# Source: https://github.com/bazelbuild/rules_cc/blob/6fd317b2ae0534a29db7085605b0262849e62f93/cc/common/cc_helper.bzl#L585
def _lookup_var(ctx, additional_vars, var):
    expanded_make_var_ctx = ctx.var.get(var)
    expanded_make_var_additional = additional_vars.get(var)
    if expanded_make_var_additional != None:
        return expanded_make_var_additional
    if expanded_make_var_ctx != None:
        return expanded_make_var_ctx
    fail("{}: {} not defined".format(ctx.label, "$(" + var + ")"))

# Source: https://github.com/bazelbuild/rules_cc/blob/6fd317b2ae0534a29db7085605b0262849e62f93/cc/common/cc_helper.bzl#L594
def _expand_nested_variable(ctx, additional_vars, exp, execpath = True, targets = []):
    # If make variable is predefined path variable(like $(location ...))
    # we will expand it first.
    if exp.find(" ") != -1:
        if not execpath:
            if exp.startswith("location"):
                exp = exp.replace("location", "rootpath", 1)
        data_targets = []
        if ctx.attr.data != None:
            data_targets = ctx.attr.data

        # Make sure we do not duplicate targets.
        unified_targets_set = {}
        for data_target in data_targets:
            unified_targets_set[data_target] = True
        for target in targets:
            unified_targets_set[target] = True
        return ctx.expand_location("$({})".format(exp), targets = unified_targets_set.keys())

    # Recursively expand nested make variables, but since there is no recursion
    # in Starlark we will do it via for loop.
    unbounded_recursion = True

    # The only way to check if the unbounded recursion is happening or not
    # is to have a look at the depth of the recursion.
    # 10 seems to be a reasonable number, since it is highly unexpected
    # to have nested make variables which are expanding more than 10 times.
    for _ in range(10):
        exp = _lookup_var(ctx, additional_vars, exp)
        if len(exp) >= 3 and exp[0] == "$" and exp[1] == "(" and exp[len(exp) - 1] == ")":
            # Try to expand once more.
            exp = exp[2:len(exp) - 1]
            continue
        unbounded_recursion = False
        break

    if unbounded_recursion:
        fail("potentially unbounded recursion during expansion of {}".format(exp))
    return exp

# Source: https://github.com/bazelbuild/rules_cc/blob/6fd317b2ae0534a29db7085605b0262849e62f93/cc/common/cc_helper.bzl#L634
def _expand(ctx, expression, additional_make_variable_substitutions, execpath = True, targets = []):
    idx = 0
    last_make_var_end = 0
    result = []
    n = len(expression)
    for _ in range(n):
        if idx >= n:
            break
        if expression[idx] != "$":
            idx += 1
            continue

        idx += 1

        # We've met $$ pattern, so $ is escaped.
        if idx < n and expression[idx] == "$":
            idx += 1
            result.append(expression[last_make_var_end:idx - 1])
            last_make_var_end = idx
            # We might have found a potential start for Make Variable.

        elif idx < n and expression[idx] == "(":
            # Try to find the closing parentheses.
            make_var_start = idx
            make_var_end = make_var_start
            for j in range(idx + 1, n):
                if expression[j] == ")":
                    make_var_end = j
                    break

            # Note we cannot go out of string's bounds here,
            # because of this check.
            # If start of the variable is different from the end,
            # we found a make variable.
            if make_var_start != make_var_end:
                # Some clarifications:
                # *****$(MAKE_VAR_1)*******$(MAKE_VAR_2)*****
                #                   ^       ^          ^
                #                   |       |          |
                #   last_make_var_end  make_var_start make_var_end
                result.append(expression[last_make_var_end:make_var_start - 1])
                make_var = expression[make_var_start + 1:make_var_end]
                exp = _expand_nested_variable(ctx, additional_make_variable_substitutions, make_var, execpath, targets)
                result.append(exp)

                # Update indexes.
                idx = make_var_end + 1
                last_make_var_end = idx

    # Add the last substring which would be skipped by for loop.
    if last_make_var_end < n:
        result.append(expression[last_make_var_end:n])

    return "".join(result)

# Source: https://github.com/bazelbuild/rules_cc/blob/6fd317b2ae0534a29db7085605b0262849e62f93/cc/common/cc_helper.bzl#L888
def _expand_single_make_variable(ctx, token, additional_make_variable_substitutions):
    if len(token) < 3:
        return None
    if token[0] != "$" or token[1] != "(" or token[len(token) - 1] != ")":
        return None
    unexpanded_var = token[2:len(token) - 1]
    expanded_var = _expand_nested_variable(ctx, additional_make_variable_substitutions, unexpanded_var)
    return expanded_var

# == COPYPASTE ENDS ===

# This funnction is almost idential to the one that can be found in the rules_cc
# However it does not hardcode the source of additional_inpputs (they are not retrieved from attr)
# Source: https://github.com/bazelbuild/rules_cc/blob/6fd317b2ae0534a29db7085605b0262849e62f93/cc/common/cc_helper.bzl#L860
def _expand_make_variables_for_copts(ctx, tokenization, unexpanded_tokens, additional_make_variable_substitutions, additional_inputs = []):
    tokens = []
    targets = []
    for additional_compiler_input in additional_inputs:
        targets.append(additional_compiler_input)
    for token in unexpanded_tokens:
        if tokenization:
            expanded_token = _expand(ctx, token, additional_make_variable_substitutions, targets = targets)
            rules_cc_helper.tokenize(tokens, expanded_token)
        else:
            exp = _expand_single_make_variable(ctx, token, additional_make_variable_substitutions)
            if exp != None:
                rules_cc_helper.tokenize(tokens, exp)
            else:
                tokens.append(_expand(ctx, token, additional_make_variable_substitutions, targets = targets))
    return tokens

def _extract_headers(files):
    hdrs = []
    if not files:
        return hdrs

    for file in files:
        extension = "." + file.extension
        if not extension in _EXTENSIONS.cc_header():
            continue

        hdrs.append(file)

    return hdrs

def _extract_sources(files):
    srcs = []
    if not files:
        return srcs

    for file in files:
        extension = "." + file.extension
        if not extension in _EXTENSIONS.cc_source():
            continue

        srcs.append(file)

    return srcs

def _get_compilation_defines(ctx, defines = [], deps = [], additional_make_variable_substitutions = {}, additional_targets = []):
    results = []
    if not defines:
        return results

    targets = [dep for dep in deps]
    targets.extend(additional_targets)

    for define in defines:
        expanded_define = _expand(ctx, define, additional_make_variable_substitutions, targets = targets)

        # Author's soap box: love the design of tokenize not returning a list..
        tokens = []
        rules_cc_helper.tokenize(tokens, expanded_define)

        if len(tokens) == 1:
            results.append(tokens[0])
        elif len(tokens) == 0:
            fail("empty definition of defines is not allowed")
        else:
            fail("definition of defines contains too many tokens (found {}, expecting exactly one)".format(len(tokens)))

    return results

def _get_compilation_opts(ctx, opts, feature_configuration, additional_make_variable_substitutions = {}, additional_inputs = []):
    if not opts:
        return []

    tokenization = not (cc_common.is_enabled(feature_configuration = feature_configuration, feature_name = "no_copts_tokenization"))
    return _expand_make_variables_for_copts(ctx, tokenization, opts, additional_make_variable_substitutions, additional_inputs)

def _get_linking_opts(ctx, opts, additional_make_variable_substitutions = {}, additional_inputs = []):
    if not opts:
        return []

    # TODO: Is this expansion sufficienct?
    results = []
    for opt in opts:
        results.append(
            _expand(ctx, opt, additional_make_variable_substitutions, targets = additional_inputs),
        )

    return results

def _prepare_for_compilation(
        sctx,
        input_hdrs_map,
        input_hdrs,
        input_implementation_hdrs,
        input_deps,
        input_includes):
    """Materialize information from hdrs map.

    This function creates a epheremal directory, that contains all of the
    patterns specified within hdrs_map providers, thus making them all
    available under singular, temporary include statment.

    Args:
        sctx: subrule context
        input_hdrs_map: list of HdrsMapInfo which should be used for materialization of compilation context
        input_hdrs: direct headers provided to the action
        input_implementation_hdrs: direct headers provided to the action
        input_deps: dependencies specified for the action
        input_includes: include statements specified for the action
    """
    hdrs = [h for h in input_hdrs]
    implementation_hdrs = [h for h in input_implementation_hdrs]
    deps = [d for d in input_deps]

    hdrs_map = input_hdrs_map if input_hdrs_map else new_hdrs_map()

    # Pattern of '{filename}' resolves to any direct header file of the rule instance
    hdrs_map.pin_down_non_globs(hdrs = hdrs + implementation_hdrs)

    # Traverse dependencies and extract:
    # HdrsMapInfo (trainsitive), CcInfo (first order) and CcSharedLibraryInfo (first order)
    deps_pub_hdrs, deps_prv_hdrs, hdrs_map, deps_deps = quotient_map_hdrs_map_infos(
        targets = deps,
        hdrs = None,
        implementation_hdrs = None,
        hdrs_map = hdrs_map,
        hdrs_map_deps = None,
        traverse_deps = True,
    )
    hdrs = depset(direct = hdrs, transitive = [deps_pub_hdrs])
    implementation_hdrs = depset(direct = implementation_hdrs, transitive = [deps_prv_hdrs])
    deps = depset(direct = deps, transitive = [deps_deps])

    # Materialize mappings
    hdrs_extra_include_path, hdrs_extra_files = materialize_hdrs_mapping(
        sctx.label,
        sctx.actions,
        hdrs_map,
        hdrs,
    )
    if hdrs_extra_files:
        hdrs = depset(direct = hdrs_extra_files, transitive = [hdrs])

    implementation_hdrs_extra_include_path, implementation_hdrs_extra_files = materialize_hdrs_mapping(
        sctx.label,
        sctx.actions,
        hdrs_map,
        implementation_hdrs,
    )
    if implementation_hdrs_extra_files:
        implementation_hdrs = depset(direct = implementation_hdrs_extra_files, transitive = [implementation_hdrs])

    includes = input_includes if input_includes else []
    if hdrs_extra_include_path:
        includes.append(hdrs_extra_include_path)
    if implementation_hdrs_extra_include_path:
        includes.append(implementation_hdrs_extra_include_path)

    return struct(
        hdrs_map = hdrs_map,
        hdrs = hdrs,
        implementation_hdrs = implementation_hdrs,
        includes = includes,
        deps = deps,
    )

def _expand_make_variables_in_defines(ctx, cc_info, action_kwargs, defines, local = False):
    amvs = rules_cc_helper.get_toolchain_global_make_variables(cc_info.cc_toolchain)
    amvs.update(rules_cc_helper.get_cc_flags_make_variable(ctx, cc_info.cc_feature_configuration, cc_info.cc_toolchain))

    defines = _get_compilation_defines(
        ctx,
        defines,
        action_kwargs.get("deps", []),
        amvs,
        action_kwargs.get("additional_inputs", []) if local else [],
    ) + rules_cc_helper.get_local_defines_for_runfiles_lookup(ctx, action_kwargs.get("deps", [])) if local else []

    return defines

def _expand_make_variables_in_copts(ctx, cc_info, action_kwargs, opts):
    amvs = rules_cc_helper.get_toolchain_global_make_variables(cc_info.cc_toolchain)
    amvs.update(rules_cc_helper.get_cc_flags_make_variable(ctx, cc_info.cc_feature_configuration, cc_info.cc_toolchain))

    return _get_compilation_opts(
        ctx,
        opts,
        cc_info.cc_feature_configuration,
        amvs,
        action_kwargs.get("additional_inputs", []),
    )

def _expand_make_variables_in_linkopts(ctx, cc_info, action_kwargs, opts):
    amvs = rules_cc_helper.get_toolchain_global_make_variables(cc_info.cc_toolchain)
    amvs.update(rules_cc_helper.get_cc_flags_make_variable(ctx, cc_info.cc_feature_configuration, cc_info.cc_toolchain))

    return _get_linking_opts(
        ctx,
        opts,
        amvs,
        action_kwargs.get("additional_inputs", []),
    )

cc_helper = struct(
    expand_make_variables_in_copts = _expand_make_variables_in_copts,
    expand_make_variables_in_defines = _expand_make_variables_in_defines,
    expand_make_variables_in_linkopts = _expand_make_variables_in_linkopts,
    extensions = _EXTENSIONS,
    extract_headers = _extract_headers,
    extract_sources = _extract_sources,
    get_compilation_defines = _get_compilation_defines,
    get_compilation_opts = _get_compilation_opts,
    get_linking_opts = _get_linking_opts,
    prepare_for_compilation = _prepare_for_compilation,
)
