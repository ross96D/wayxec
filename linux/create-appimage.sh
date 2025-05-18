#!/bin/sh
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
