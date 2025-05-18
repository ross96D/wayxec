#!/bin/sh
rm -rf AppDir
cp -r build/linux/x64/release/bundle AppDir
echo "
[Desktop Entry]
Name=RLaunch
Exec=RLaunch
Type=Application
Icon=placeholder
Categories=Utility;
" >> AppDir/rlaunch.desktop
mv AppDir/flutter_gtk_shell_layer_test AppDir/AppRun
touch AppDir/placeholder.svg

appimagetool AppDir
