#!/bin/bash

set -e

APP_PATH="build/Build/Products/Release/RARExt.app"
PKG_ROOT="build/pkg-root"
SCRIPTS_DIR="build/pkg-scripts"
PKG_OUTPUT="build/RARExt.pkg"

rm -rf "$PKG_ROOT" "$SCRIPTS_DIR"
mkdir -p "$PKG_ROOT/Applications"
mkdir -p "$SCRIPTS_DIR"

cp -R "$APP_PATH" "$PKG_ROOT/Applications/"
cp scripts/register-extension.sh "$PKG_ROOT/Applications/RARExt.app/Contents/Resources/"
chmod +x "$PKG_ROOT/Applications/RARExt.app/Contents/Resources/register-extension.sh"
cp scripts/postinstall "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/postinstall"

pkgbuild --root "$PKG_ROOT" \
         --scripts "$SCRIPTS_DIR" \
         --identifier "com.example.rarext" \
         --version "1.0" \
         --install-location "/" \
         "$PKG_OUTPUT"

echo "Package created: $PKG_OUTPUT"
echo ""
echo "To install:"
echo "  sudo installer -pkg $PKG_OUTPUT -target /"
echo ""
echo "The extension will be automatically registered during installation."
echo "After installation, enable it in System Settings > Extensions > Finder"
