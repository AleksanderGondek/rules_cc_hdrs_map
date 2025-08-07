""" This module serves chiefly as a vehicle for exposing 'privaete' cc_helper methods to current rule set. """

load("@rules_cc//cc/common:cc_helper.bzl", rules_cc_helper = "cc_helper")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map.bzl", "materialize_hdrs_mapping", "new_hdrs_map")
load("@rules_cc_hdrs_map//cc_hdrs_map/providers:hdrs_map_info.bzl", "HdrsMapInfo", "quotient_map_hdrs_map_infos")

# TODO: Perhaps a PR to `rules_cc` to expose extensions method?
# https://github.com/bazelbuild/bazel/blob/6d811c80720584eac50372b866d063aebd37e2e5/src/main/starlark/builtins_bzl/common/cc/cc_helper_internal.bzl#L94
CC_HEADER_EXTENSIONS = [
    ".h",
    ".hh",
    ".hpp",
    ".ipp",
    ".hxx",
    ".h++",
    ".inc",
    ".inl",
    ".tlh",
    ".tli",
    ".H",
    ".tcc",
]
CC_SOURCE_EXTENSIONS = [
    ".c",
    ".cc",
    ".cpp",
    ".cxx",
    ".c++",
    ".C",
    ".cu",
    ".cl",
    # Non-standard additions:
    # assembly
    ".s",
    ".S",
    ".asm",
    # pre-processed files
    ".i",
    ".ii",
]

# Author soap box:
# I do not understand the obsession with making everything private,
# especially that Starlark is based on Python.
# Here it is making things more convoluted, because there is no easy
# way I can extract 'private' methods from either bultins cc_helper or rules_cc cc_helper
# The result is a patch work.

# === PATCHWORK BEIGNS ===
# Source: https://github.com/bazelbuild/rules_cc/blob/3dce172deec2a4563c28eae02a8bb18555abafb2/cc/common/cc_helper.bzl#L140
# Source: https://github.com/bazelbuild/bazel/blob/49e43bbd4a3a3aa5f0f00158dff15914b69b6e85/src/main/starlark/builtins_bzl/common/cc/cc_library.bzl#L53

def _lookup_var(sctx, extra_ctx_members, additional_vars, var):
    expanded_make_var_ctx = extra_ctx_members.var.get(var)
    expanded_make_var_additional = additional_vars.get(var)
    if expanded_make_var_additional != None:
        return expanded_make_var_additional
    if expanded_make_var_ctx != None:
        return expanded_make_var_ctx
    fail("{}: {} not defined".format(sctx.label, "$(" + var + ")"))

def _expand_nested_variable(sctx, extra_ctx_members, additional_vars, exp, execpath = True, targets = []):
    # If make variable is predefined path variable(like $(location ...))
    # we will expand it first.
    if exp.find(" ") != -1:
        if not execpath:
            if exp.startswith("location"):
                exp = exp.replace("location", "rootpath", 1)
        data_targets = []
        if extra_ctx_members.data_attr != None:
            data_targets = extra_ctx_members.data_attr

        # Make sure we do not duplicate targets.
        unified_targets_set = {}
        for data_target in data_targets:
            unified_targets_set[data_target] = True
        for target in targets:
            unified_targets_set[target] = True
        return extra_ctx_members.expand_location("$({})".format(exp), targets = unified_targets_set.keys())

    # Recursively expand nested make variables, but since there is no recursion
    # in Starlark we will do it via for loop.
    unbounded_recursion = True

    # The only way to check if the unbounded recursion is happening or not
    # is to have a look at the depth of the recursion.
    # 10 seems to be a reasonable number, since it is highly unexpected
    # to have nested make variables which are expanding more than 10 times.
    for _ in range(10):
        exp = _lookup_var(sctx, extra_ctx_members, additional_vars, exp)
        if len(exp) >= 3 and exp[0] == "$" and exp[1] == "(" and exp[len(exp) - 1] == ")":
            # Try to expand once more.
            exp = exp[2:len(exp) - 1]
            continue
        unbounded_recursion = False
        break

    if unbounded_recursion:
        fail("potentially unbounded recursion during expansion of {}".format(exp))
    return exp

def _expand(sctx, extra_ctx_members, expression, targets, additional_make_variable_substitutions, execpath = True):
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
                exp = _expand_nested_variable(sctx, extra_ctx_members, additional_make_variable_substitutions, make_var, execpath, targets)
                result.append(exp)

                # Update indexes.
                idx = make_var_end + 1
                last_make_var_end = idx

    # Add the last substring which would be skipped by for loop.
    if last_make_var_end < n:
        result.append(expression[last_make_var_end:n])

    return "".join(result)

# Tries to expand a single make variable from token.
# If token has additional characters other than ones
# corresponding to make variable returns None.
def _expand_single_make_variable(sctx, extra_ctx_members, token, additional_make_variable_substitutions):
    if len(token) < 3:
        return None
    if token[0] != "$" or token[1] != "(" or token[len(token) - 1] != ")":
        return None
    unexpanded_var = token[2:len(token) - 1]
    expanded_var = _expand_nested_variable(sctx, extra_ctx_members, additional_make_variable_substitutions, unexpanded_var)
    return expanded_var

def _expand_make_variables_for_copts(sctx, extra_ctx_members, tokenization, unexpanded_tokens, additional_make_variable_substitutions, additional_inputs = []):
    tokens = []
    targets = []
    for additional_compiler_input in additional_inputs:
        targets.append(additional_compiler_input)
    for token in unexpanded_tokens:
        if tokenization:
            expanded_token = _expand(sctx, extra_ctx_members, token, targets, additional_make_variable_substitutions)
            rules_cc_helper.tokenize(tokens, expanded_token)
        else:
            exp = _expand_single_make_variable(sctx, extra_ctx_members, token, additional_make_variable_substitutions)
            if exp != None:
                rules_cc_helper.tokenize(tokens, exp)
            else:
                tokens.append(_expand(sctx, extra_ctx_members, token, targets, additional_make_variable_substitutions))
    return tokens

def _tool_path(cc_toolchain, tool):
    return cc_toolchain._tool_paths.get(tool, None)

# Authors soap box: Christ.
def _get_toolchain_global_make_variables(cc_toolchain):
    result = {
        "CC": _tool_path(cc_toolchain, "gcc"),
        "AR": _tool_path(cc_toolchain, "ar"),
        "NM": _tool_path(cc_toolchain, "nm"),
        "LD": _tool_path(cc_toolchain, "ld"),
        "STRIP": _tool_path(cc_toolchain, "strip"),
        "C_COMPILER": cc_toolchain.compiler,
    }
    obj_copy_tool = _tool_path(cc_toolchain, "objcopy")
    if obj_copy_tool != None:
        # objcopy is optional in Crostool.
        result["OBJCOPY"] = obj_copy_tool
    gcov_tool = _tool_path(cc_toolchain, "gcov-tool")
    if gcov_tool != None:
        # gcovtool is optional in Crostool.
        result["GCOVTOOL"] = gcov_tool

    libc = cc_toolchain.libc
    if libc.startswith("glibc-"):
        # Strip "glibc-" prefix.
        result["GLIBC_VERSION"] = libc[6:]
    else:
        result["GLIBC_VERSION"] = libc

    abi_glibc_version = cc_toolchain._abi_glibc_version
    if abi_glibc_version != None:
        result["ABI_GLIBC_VERSION"] = abi_glibc_version

    abi = cc_toolchain._abi
    if abi != None:
        result["ABI"] = abi

    result["CROSSTOOLTOP"] = cc_toolchain._crosstool_top_path
    return result

def _contains_sysroot(original_cc_flags, feature_config_cc_flags):
    SYSROOT_FLAG = "--sysroot="
    if SYSROOT_FLAG in original_cc_flags:
        return True
    for flag in feature_config_cc_flags:
        if SYSROOT_FLAG in flag:
            return True

    return False

def _get_cc_flags_make_variable(cc_toolchain, feature_configuration):
    SYSROOT_FLAG = "--sysroot="
    original_cc_flags = cc_toolchain._legacy_cc_flags_make_variable
    sysroot_cc_flag = ""
    if cc_toolchain.sysroot != None:
        sysroot_cc_flag = SYSROOT_FLAG + cc_toolchain.sysroot

    build_vars = cc_toolchain._build_variables
    feature_config_cc_flags = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = "cc-flags-make-variable",
        variables = build_vars,
    )
    cc_flags = [original_cc_flags]

    # Only add sysroots flag if nothing else adds sysroot, BUT it must appear
    # before the feature config flags.
    if not _contains_sysroot(original_cc_flags, feature_config_cc_flags):
        cc_flags.append(sysroot_cc_flag)
    cc_flags.extend(feature_config_cc_flags)
    return {"CC_FLAGS": " ".join(cc_flags)}

def _get_local_defines_for_runfiles_lookup(ctx, all_deps):
    _RUNFILES_LIBRARY_TARGET = Label("@rules_cc//cc/runfiles")
    _LEGACY_RUNFILES_LIBRARY_TARGET = Label("@bazel_tools//tools/cpp/runfiles")
    for dep in all_deps:
        if dep.label == _RUNFILES_LIBRARY_TARGET or dep.label == _LEGACY_RUNFILES_LIBRARY_TARGET:
            return ["BAZEL_CURRENT_REPOSITORY=\"{}\"".format(ctx.label.workspace_name)]
    return []

# == PATCHWORK ENDS ===

def _extract_headers(files):
    hdrs = []
    if not files:
        return hdrs

    for file in files:
        extension = "." + file.extension
        if not extension in CC_HEADER_EXTENSIONS:
            continue

        hdrs.append(file)

    return hdrs

def _extract_sources(files):
    srcs = []
    if not files:
        return srcs

    for file in files:
        extension = "." + file.extension
        if not extension in CC_SOURCE_EXTENSIONS:
            continue

        srcs.append(file)

    return srcs

def _get_compilation_defines(sctx, extra_ctx_members, defines = [], deps = [], additional_make_variable_substitutions = {}, additional_targets = []):
    targets = [dep for dep in deps]
    targets.extend(additional_targets)

    results = []
    for define in defines:
        expanded_define = _expand(sctx, extra_ctx_members, define, targets, additional_make_variable_substitutions)

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

def _get_compilation_opts(sctx, extra_ctx_members, opts, feature_configuration, additional_make_variable_substitutions = {}, additional_inputs = []):
    tokenization = not (cc_common.is_enabled(feature_configuration = feature_configuration, feature_name = "no_copts_tokenization"))
    return _expand_make_variables_for_copts(sctx, extra_ctx_members, tokenization, opts, additional_make_variable_substitutions, additional_inputs)

def _get_linking_opts(sctx, extra_ctx_members, opts, additional_make_variable_substitutions = {}, additional_inputs = []):
    # TODO: Is this expansion sufficienct?
    results = []
    for opt in opts:
        results.append(
            _expand(sctx, extra_ctx_members, opt, additional_inputs, additional_make_variable_substitutions),
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

cc_helper = struct(
    extract_headers = _extract_headers,
    extract_sources = _extract_sources,
    get_compilation_defines = _get_compilation_defines,
    get_compilation_opts = _get_compilation_opts,
    get_linking_opts = _get_linking_opts,
    get_local_defines_for_runfiles_lookup = _get_local_defines_for_runfiles_lookup,
    get_cc_flags_make_variable = _get_cc_flags_make_variable,
    get_toolchain_global_make_variables = _get_toolchain_global_make_variables,
    prepare_for_compilation = _prepare_for_compilation,
)
