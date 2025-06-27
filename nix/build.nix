{ appimageTools, fetchurl, pkgs }:

# wrap the existing release appImage so it runs on nixOS
appimageTools.wrapType2 rec {

  pname = "wayxec";
  version = "1.0.5";

  src = fetchurl {
    url =
      "https://github.com/ross96D/wayxec/releases/download/1.0.5/wayxec-x86_64.AppImage";
    hash = "sha256-E5po2aLsCVxN8nXgEUMzzkg5PNVQUL8g330950v8K1c=";
  };

  extraPkgs = pkgs: [ pkgs.gtk-layer-shell pkgs.libepoxy ];

}
