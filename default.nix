{ ... }:
let
  flake = (import
    (let lockFile = builtins.fromJSON (builtins.readFile ./flake.lock);
    in builtins.fetchTarball {
      url =
        "https://github.com/edolstra/flake-compat/archive/${lockFile.nodes.flake-compat.locked.rev}.tar.gz";
      sha256 = lockFile.nodes.flake-compat.locked.narHash;
    }) { src = ./.; }).defaultNix;
in flake.outputs.rise-and-fall.${builtins.currentSystem}

