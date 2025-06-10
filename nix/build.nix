{
  appimageTools,
  fetchurl,
  pkgs
} :
# wrap the existing release appImage so it runs on nixOS
appimageTools.wrapType2 rec {
  pname = "wayxec";
  version = "1.0.1";

  src = fetchurl {
    url = "https://github.com/ross96D/wayxec/releases/download/1.0.1/wayxec-x86_64.AppImage";
    hash = "sha256-vSqfhpNbnoH8B/CApd0xIvZlYeeBv8vtJ+sizalSsUg=";
  };

  extraPkgs = pkgs: [
    pkgs.gtk-layer-shell
    pkgs.libepoxy
  ];

}


  # this is the method that we were originally using, which compiles
  # from source. Hard to do because of rust deps that are downloaded
  # at compile time, which nix doesn'r allow
#{
#  flutter319,
#  fetchFromGitHub,
#  pkgs
#} :
#flutter319.buildFlutterApp {
#
#  src = fetchFromGitHub {
#    # https://github.com/ross96D/wayxec
#    owner = "ross96D";
#    repo = "wayxec";
#    rev = "1.0.1";
#    sha256 = "sha256-c5hjOi1F0fsNgGqE+bsQy7fsY0ZYXUz3buDc/U9GPSo=";
#  };
#
#  buildInputs = with pkgs; [
#    gtk-layer-shell
#    corrosion
#  ];
#
#  autoPubspecLock = src + "/pubspec.lock";
#
#  buildPhase = ''
#    runHook preBuild
#    mkdir -p build/flutter_assets/fonts
#    flutter build linux apps/firmware_updater/lib/main.dart
#    runHook postBuild
#  '';
#}
