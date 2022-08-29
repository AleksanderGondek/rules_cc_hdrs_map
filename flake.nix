{
  description = "Escape weird includes path hell with header maps";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs_latest.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs_latest, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      "nixpkgs" = import nixpkgs { inherit system; };
      "nixpkgs_latest" = import nixpkgs_latest { inherit system; };
    });
}
