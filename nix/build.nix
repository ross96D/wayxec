{
  appimageTools,
  fetchurl,
  pkgs
} :
# wrap the existing release appImage so it runs on nixOS
appimageTools.wrapType2 rec {
  pname = "wayxec";
  version = "1.0.4";

  src = fetchurl {
    url = "https://github.com/ross96D/wayxec/releases/download/1.0.4/wayxec-x86_64.AppImage";
    hash = "sha256-vSqfhpNbnoH8B/CApd0xIvZlYeeBv8vtJ+sizalSsUg=";
  };

  extraPkgs = pkgs: [
    pkgs.gtk-layer-shell
    pkgs.libepoxy
  ];

}
