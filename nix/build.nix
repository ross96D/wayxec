{ appimageTools, fetchurl, pkgs }:

# wrap the existing release appImage so it runs on nixOS
appimageTools.wrapType2 rec {

  pname = "wayxec";
  version = "1.0.9";

  src = fetchurl {
    url =
      "https://github.com/ross96D/wayxec/releases/download/${version}/wayxec-x86_64.AppImage";
    hash = "sha256-UDutI4xxUMY8J2dSqIVP0i7tNiLXeGleSzWwB8fK6Ac=";
  };

  extraPkgs = pkgs: [ pkgs.gtk-layer-shell pkgs.libepoxy ];

}
