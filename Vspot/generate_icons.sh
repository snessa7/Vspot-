#!/bin/bash

# Script to generate app icon sizes from source image
# Usage: ./generate_icons.sh /path/to/source/image.png

SOURCE_IMAGE="$1"
ASSETS_DIR="VspotApp/Assets.xcassets/AppIcon.appiconset"

if [ -z "$SOURCE_IMAGE" ]; then
    echo "Please provide the path to your V logo image"
    echo "Usage: ./generate_icons.sh /path/to/v-logo.png"
    exit 1
fi

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image not found at $SOURCE_IMAGE"
    exit 1
fi

echo "Generating app icons from $SOURCE_IMAGE..."

# Check if sips is available (built-in macOS tool)
if ! command -v sips &> /dev/null; then
    echo "Error: sips command not found. This script requires macOS."
    exit 1
fi

# Generate all required sizes in PNG format
sips -z 16 16 "$SOURCE_IMAGE" --out "$ASSETS_DIR/icon_16x16.png" -s format png
sips -z 32 32 "$SOURCE_IMAGE" --out "$ASSETS_DIR/icon_16x16@2x.png" -s format png
sips -z 32 32 "$SOURCE_IMAGE" --out "$ASSETS_DIR/icon_32x32.png" -s format png
sips -z 64 64 "$SOURCE_IMAGE" --out "$ASSETS_DIR/icon_32x32@2x.png" -s format png
sips -z 128 128 "$SOURCE_IMAGE" --out "$ASSETS_DIR/icon_128x128.png" -s format png
sips -z 256 256 "$SOURCE_IMAGE" --out "$ASSETS_DIR/icon_128x128@2x.png" -s format png
sips -z 256 256 "$SOURCE_IMAGE" --out "$ASSETS_DIR/icon_256x256.png" -s format png
sips -z 512 512 "$SOURCE_IMAGE" --out "$ASSETS_DIR/icon_256x256@2x.png" -s format png
sips -z 512 512 "$SOURCE_IMAGE" --out "$ASSETS_DIR/icon_512x512.png" -s format png
sips -z 1024 1024 "$SOURCE_IMAGE" --out "$ASSETS_DIR/icon_512x512@2x.png" -s format png

echo "✅ App icons generated successfully!"
echo "Icons saved to: $ASSETS_DIR"