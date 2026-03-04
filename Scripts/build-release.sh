#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
SCHEME="DatabricksMenuBar"
PROJECT="$PROJECT_DIR/DatabricksMenuBar.xcodeproj"

echo "==> Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Building release archive..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$BUILD_DIR/$SCHEME.xcarchive" \
    -quiet

echo "==> Exporting app..."
# For ad-hoc (no Developer ID), copy directly from archive
APP_PATH="$BUILD_DIR/$SCHEME.xcarchive/Products/Applications/$SCHEME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: App not found at $APP_PATH"
    exit 1
fi

RELEASE_DIR="$BUILD_DIR/release"
mkdir -p "$RELEASE_DIR"
cp -R "$APP_PATH" "$RELEASE_DIR/"

echo "==> Creating DMG..."
if command -v create-dmg &>/dev/null; then
    create-dmg \
        --volname "Databricks Menu Bar" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$SCHEME.app" 150 190 \
        --app-drop-link 450 190 \
        "$BUILD_DIR/$SCHEME.dmg" \
        "$RELEASE_DIR/$SCHEME.app" || true
    echo "==> DMG created at $BUILD_DIR/$SCHEME.dmg"
else
    echo "==> create-dmg not found. Install with: brew install create-dmg"
    echo "==> App is available at: $RELEASE_DIR/$SCHEME.app"
fi

echo "==> Done!"
echo "    App: $RELEASE_DIR/$SCHEME.app"
