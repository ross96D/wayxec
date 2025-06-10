{ pkgs ? import <nixpkgs> {} }:
let
  wayxecBuild = import ./build.nix;
  wayxec = pkgs.callPackage wayxecBuild { };
in
  pkgs.mkShell {
    buildInputs = [ wayxec ];
  }
