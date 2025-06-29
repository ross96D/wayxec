{ pkgs ? import <nixpkgs> { }, }:

let
  unstablenixpkgs = fetchTarball
    "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  unstablepkgs = import unstablenixpkgs {
    config = { };
    overlays = [ ];
  };

in pkgs.mkShell {

  nativeBuildInputs = [ ];
  buildInputs = [
    unstablepkgs.flutter
    pkgs.pkg-config
    pkgs.gtk-layer-shell
    pkgs.gtk3
    pkgs.rustc
    pkgs.cargo
    pkgs.libsysprof-capture
    pkgs.pcre2
    pkgs.util-linux
    pkgs.libselinux
    pkgs.libsepol
    pkgs.libthai
    pkgs.libdatrie
    pkgs.xorg.libXdmcp
    pkgs.lerc
    pkgs.libxkbcommon
    pkgs.libepoxy
    pkgs.xorg.libXtst
    pkgs.wget
  ];

}
