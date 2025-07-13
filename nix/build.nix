{ appimageTools, fetchurl, pkgs }:

# wrap the existing release appImage so it runs on nixOS
appimageTools.wrapType2 {

  pname = "wayxec";
  version = "<version>";

  src = "wayxec-x86_64.AppImage";

  extraPkgs = pkgs: [ pkgs.gtk-layer-shell pkgs.libepoxy ];

  extraInstallCommands = ''
    # Install .desktop file
    mkdir -p $out/share/applications
    cp linux/wayxec.desktop $out/share/applications

    # Install icon
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp linux/wayxec.png $out/share/icons/hicolor/256x256/apps
  '';
}
