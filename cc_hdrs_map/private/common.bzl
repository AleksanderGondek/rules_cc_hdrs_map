""" Contains common logic shared between rules implementation(s). """

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

    all_runfiles = ctx_runfiles_fun(files = files)
    return all_runfiles.merge_all(runfiles)
