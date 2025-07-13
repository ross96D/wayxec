{ appimageTools, fetchurl, pkgs }:

# wrap the existing release appImage so it runs on nixOS
appimageTools.wrapType2 rec {

  pname = "wayxec";
  version = "<version>";

  src = ./wayxec-x86_64.AppImage;

  extraPkgs = pkgs: [ pkgs.gtk-layer-shell pkgs.libepoxy ];

}
