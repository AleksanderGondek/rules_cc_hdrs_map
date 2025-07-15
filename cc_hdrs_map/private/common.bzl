""" Contains common logic shared between rules implementation(s). """

def prepare_default_runfiles(attr_data, ctx_runfiles_fun):
    """ aaa """
    runfiles = []
    for data_dep in attr_data:
        if data_dep[DefaultInfo].data_runfiles.files:
            runfiles.append(data_dep[DefaultInfo].data_runfiles)
        else:
            # This branch ensures interop with custom Starlark rules following
            # https://bazel.build/extending/rules#runfiles_features_to_avoid
            runfiles.append(ctx_runfiles_fun(transitive_files = data_dep[DefaultInfo].files))
            runfiles.append(data_dep[DefaultInfo].default_runfiles)

    return runfiles
