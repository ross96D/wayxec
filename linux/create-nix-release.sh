#!/bin/bash

# Validate tag_version argument
if [ $# -ne 1 ]; then
  echo "Error: Exactly one argument (tag_version) required"
  exit 1
fi

tag_version="$1"

# Copy build.nix to default.nix
cp ./nix/build.nix ./default.nix

# Replace <version> with tag_version in default.nix
sed -i "s/<version>/$tag_version/g" ./default.nix

# Create zip archive
zip -j nix-release-x86_64.zip ./wayxec-x86_64.AppImage ./default.nix ./linux/wayxec.desktop ./linux/wayxec.png
