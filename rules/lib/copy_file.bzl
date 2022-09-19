""" To be described. """

# Definitions copied near verbatim from bazel-skylib
#  Apart from exec requirements

COPY_EXECUTION_REQUIREMENTS = {
}

def _copy_cmd(invoker_label, actions, src, dst):
    # Most Windows binaries built with MSVC use a certain argument quoting
    # scheme. Bazel uses that scheme too to quote arguments. However,
    # cmd.exe uses different semantics, so Bazel's quoting is wrong here.
    # To fix that we write the command to a .bat file so no command line
    # quoting or escaping is required.
    bat = actions.declare_file(invoker_label.name + "-cmd.bat")
    actions.write(
        output = bat,
        content = "@copy /Y \"%s\" \"%s\" >NUL" % (
            src.path.replace("/", "\\"),
            dst.path.replace("/", "\\"),
        ),
        is_executable = True,
    )
    actions.run(
        inputs = [src],
        tools = [bat],
        outputs = [dst],
        executable = "cmd.exe",
        arguments = ["/C", bat.path.replace("/", "\\")],
        mnemonic = "HdrsMapIncludeMaterialize",
        progress_message = "Materializing public hdr mapping from '%{input}' to '%{output}'",
        use_default_shell_env = False,
        execution_requirements = COPY_EXECUTION_REQUIREMENTS,
    )

def _copy_shell(actions, src, dst):
    actions.run_shell(
        tools = [src],
        outputs = [dst],
        command = "cp -f \"$1\" \"$2\"",
        arguments = [src.path, dst.path],
        mnemonic = "HdrsMapIncludeMaterialize",
        progress_message = "Materializing public hdr mapping from '%{input}' to '%{output}'",
        use_default_shell_env = False,
        execution_requirements = COPY_EXECUTION_REQUIREMENTS,
    )

def copy_file(invoker_label, actions, is_windows, src, dst):
    """ To be described. """
    if is_windows:
        _copy_cmd(
            invoker_label,
            actions,
            src,
            dst,
        )
    else:
        _copy_shell(
            actions,
            src,
            dst,
        )
