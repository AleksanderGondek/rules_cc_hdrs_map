{localSystem ? builtins.currentSystem, ...} @ args: let
  external_sources = import ./nix/sources.nix;

  nixpkgs_import_args = {
    inherit localSystem;
    config = {};
  };

  nixpkgs = import external_sources.nixpkgs nixpkgs_import_args;

  devShellPackages = pkgs: (with pkgs; [
    alejandra
    bashInteractive
    bazelisk
    bazel-buildtools
    cocogitto
    findutils
    # TMP
    jdk
    git
    helix
    niv
    statix
    # Required by downloaded bazel
    zlib
  ]);

  # buildFHSEnv to be able to use bazelisk on NixOS
  devShellNixOs =
    (nixpkgs.buildFHSEnv {
      name = "rules_cc_hdrs_map-shell";

      targetPkgs = devShellPackages;

      runScript = nixpkgs.writeScript "rules_cc_hdrs_map-shell-init.sh" ''
        shellHooksPath=$(mktemp --suffix=rules_cc_hdrs_map-shell.bazelrc)
        cat <<EOF > $shellHooksPath
          # Just using an 'alias=...'
          # will not work for binaries like starpls, that execute items
          # directly from path.
          mkdir -p .bazelisk-bin
          ln -f -s ${nixpkgs.bazelisk}/bin/bazelisk .bazelisk-bin/bazel
          export PATH="$(realpath .bazelisk-bin)/:$PATH"
        EOF

        exec bash --rcfile $shellHooksPath
      '';
    })
    .env;

  # This is for environments that take slight offence to buildFHSEnv
  # being used as a dev shell - i.e. github runner, which:
  #  (1) requires extra work on Ubuntu 24.04 to even allow bubblewrap
  #  (2) is not keen to wait for the end of devShell process
  #
  # Nothing that cannot be fixed, but I want to avoid overinvesting
  # in solving buildFHSEnv problems.
  devShell = nixpkgs.mkShell {
    name = "rules_cc_hdrs_map-non_fhs_shell";
    packages = devShellPackages nixpkgs;
    shellHook = ''
      mkdir -p .bazelisk-bin
      ln -f -s ${nixpkgs.bazelisk}/bin/bazelisk .bazelisk-bin/bazel
      export PATH="$(realpath .bazelisk-bin)/:$PATH"
    '';
  };
in {
  inherit devShell devShellNixOs nixpkgs;
}
