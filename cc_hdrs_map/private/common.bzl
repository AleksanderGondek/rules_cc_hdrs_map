""" Contains common logic shared between rules implementation(s). """

load("@rules_cc//cc:defs.bzl", "CcInfo")

def _get_dynamic_libraries_for_runtime(cc_linking_context, linking_statically):
    libraries = []
    for linker_input in cc_linking_context.linker_inputs.to_list():
        libraries.extend(linker_input.libraries)

    dynamic_libraries_for_runtime = []
    for library in libraries:
        artifact = _get_dynamic_library_for_runtime_or_none(library, linking_statically)
        if artifact != None:
            dynamic_libraries_for_runtime.append(artifact)

    return dynamic_libraries_for_runtime

def _get_dynamic_library_for_runtime_or_none(library, linking_statically):
    if library.dynamic_library == None:
        return None

    if linking_statically and (library.static_library != None or library.pic_static_library != None):
        return None

    return library.dynamic_library

def _runfiles_function(dep, linking_statically):
    provider = None
    if CcInfo in dep:
        provider = dep[CcInfo]
    if provider == None:
        return depset()

    return depset(_get_dynamic_libraries_for_runtime(provider.linking_context, linking_statically))

def _retrieve_runfiles(target):
    # sequence of runfile objects
    runfiles = []

    # Handle 'feature to avoid' (data_files, default_runfiles)
    # https://bazel.build/extending/rules#runfiles_features_to_avoid
    for runfiles_source in ["runfiles", "data_files", "default_runfiles"]:
        source = getattr(target[DefaultInfo], runfiles_source, None)
        if not source:
            continue

        # TODO: Perhaps trim down the empty depsets?
        runfiles.append(source)

    return runfiles

def prepare_default_runfiles(ctx_runfiles_fun, attr_data, attr_deps, files = []):
    """ The default list of runfiles, gathered from the data attribute. """

    # sequence of runfile objects
    runfiles = []
    for attr in [attr_data, attr_deps]:
        for target in attr:
            runfiles.extend(_retrieve_runfiles(target))
            runfiles.append(ctx_runfiles_fun(transitive_files = _runfiles_function(target, False)))
            runfiles.append(ctx_runfiles_fun(transitive_files = _runfiles_function(target, True)))

    all_runfiles = ctx_runfiles_fun(files = files)
    return all_runfiles.merge_all(runfiles)
