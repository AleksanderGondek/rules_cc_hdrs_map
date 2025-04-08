""" This module exposes the copy_file action. Done to avoid dependency towards skylib (or others). """

def copy_file(ctx_actions, src, dst):
    """Copy file from a to b.

    This function will copy file from given source to specified destination.

    Args:
        src: (File) source file that should be copied. Must exist.
        dst: (File) destination file that should be created. Must be declared beforehand.
    """
    ctx_actions.run_shell(
        tools = [src],
        outputs = [dst],
        command = "cp -f \"$1\" \"$2\"",
        arguments = [src.path, dst.path],
        mnemonic = "HdrsMapIncludeMaterialize",
        progress_message = "Materializing public hdr mapping from '%{input}' to '%{output}'",
        use_default_shell_env = False,
        execution_requirements = {
            # TODO: Improve the action, so that it can run virtually anywhere
            # This is because its not ready for remote
            "no-remote": "1",
        },
    )
