#!/bin/sh
if ! type appimagetool > /dev/null; then 
    ARCH="$(uname -m)"
    wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-"$ARCH".AppImage
    chmod +x appimagetool-"$ARCH".AppImage
    if ls "$HOME"/.local/bin > /dev/null; then
        mv appimagetool-"$ARCH".AppImage "$HOME"/.local/bin
    else
        mv appimagetool-"$ARCH".AppImage /usr/bin
    fi 
fi

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

appimagetool AppDir
