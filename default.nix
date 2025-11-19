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

  # This is required to ensure that the
  # symbols libuuid needs, are compatbile
  # with the sysroot-provided libs of
  # Bazel toolchain (they are old)
  libuuid_dev = nixpkgs.stdenv.mkDerivation {
    name = "libuuid_dev";
    version = "1.3.0@linux2.31.1";

    src = builtins.fetchurl {
      url = "https://cache.nixos.org/nar/039ykinvrwg3qxhpk6mcasbi4b0lfhyag9nxv6jagrja5jwwnjn6.nar.xz";
      sha256 = "039ykinvrwg3qxhpk6mcasbi4b0lfhyag9nxv6jagrja5jwwnjn6";
    };

    nativeBuildInputs = [nixpkgs.xz nixpkgs.nix];

    unpackPhase = ''
      cat $src | xz -dc | nix-store --restore ./tmp
      mkdir -p $out/include
      mv ./tmp/include/uuid $out/include/uuid
    '';

    dontPatch = true;
    dontConfigure = true;
    dontBuild = true;
    dontCheck = true;
    dontInstall = true;
    dontFixup = true;
  };
  libuuid_lib = nixpkgs.stdenv.mkDerivation {
    name = "libuuid_lib";
    version = "1.3.0@linux2.31.1";

    src = builtins.fetchurl {
      url = "https://cache.nixos.org/nar/00sxgnrjwqcbpa7f1z4gq55gfcwfv6407xl5rq81cr0l12d4hr9n.nar.xz";
      sha256 = "00sxgnrjwqcbpa7f1z4gq55gfcwfv6407xl5rq81cr0l12d4hr9n";
    };

    nativeBuildInputs = [nixpkgs.xz nixpkgs.nix];

    unpackPhase = ''
      cat $src | xz -dc | nix-store --restore ./tmp
      mkdir -p $out/lib
      mv ./tmp/lib $out/
    '';

    dontPatch = true;
    dontConfigure = true;
    dontBuild = true;
    dontCheck = true;
    dontInstall = true;
    dontFixup = true;
  };

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

          # TODO: Retrieve sol via http_archive
          ln -f -s ${libuuid_dev}/include ./examples/libuuid/include
          ln -f -s ${libuuid_lib}/lib ./examples/libuuid/lib
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

      # TODO: Retrieve sol via http_archive
      ln -f -s ${libuuid_dev}/include ./examples/libuuid/include
      ln -f -s ${libuuid_lib}/lib ./examples/libuuid/lib
    '';
  };
in {
  inherit devShell devShellNixOs nixpkgs;
}
