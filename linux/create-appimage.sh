#!/bin/sh
APPIMAGETOOL=""
if ! type appimagetool > /dev/null; then 
    ARCH="$(uname -m)"
    # shellcheck disable=SC2210
    wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-"$ARCH".AppImage > /dev/null 2>1
    chmod +x appimagetool-"$ARCH".AppImage
    APPIMAGETOOL="$PWD/appimagetool-$ARCH.AppImage"
else
    APPIMAGETOOL=$(which appimagetool)
fi

echo "appimagetoo located in $APPIMAGETOOL"

rm -rf AppDir
cp -r build/linux/x64/release/bundle AppDir
echo "
[Desktop Entry]
Name=wayxec
Exec=wayxec
Type=Application
Icon=placeholder
Categories=Utility;
" >> AppDir/wayxec.desktop
mv AppDir/wayxec AppDir/AppRun
touch AppDir/placeholder.svg

$APPIMAGETOOL AppDir "$@"
