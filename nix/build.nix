{ appimageTools, fetchurl, pkgs }:

let
  derivationDir = builtins.path { path = ./.; };
  appImage = "${derivationDir}/wayxec-x86_64.AppImage";

in appimageTools.wrapType2 {

  pname = "wayxec";
  version = "<version>";

  src = appImage;

  extraPkgs = pkgs: [ pkgs.gtk-layer-shell pkgs.libepoxy ];

  postInstall = ''
    # Install .desktop file
    mkdir -p $out/share/applications
    cp linux/wayxec.desktop $out/share/applications

    # Install icon
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp linux/wayxec.png $out/share/icons/hicolor/256x256/apps
  '';
}
