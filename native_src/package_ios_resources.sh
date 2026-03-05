#!/bin/bash
# ============================================================
# Package iOS Resources for Release
# ============================================================
# Collects all iOS SDK resources, dynamic frameworks, and tools
# into a self-contained ios_resources/ directory for distribution.
#
# Run this AFTER building from source (pod install + build_ios.sh).
# The resulting ios_resources/ folder should be included in the
# GitHub Release alongside yodo1mas.ane and postprocess_ipa.sh.
#
# Usage:
#   cd native_src
#   ./package_ios_resources.sh
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IOS_DIR="$SCRIPT_DIR/ios"
PODS_DIR="$IOS_DIR/Pods"
BUILD_DIR="$IOS_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/ios_resources"

echo "============================================"
echo "  Packaging iOS Resources for Release"
echo "============================================"

# Clean previous output
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/frameworks"

# ---- SDK Resource Files (plists + bundles) ----
echo ""
echo "[1/3] Copying SDK resource files..."

copy_if_exists() {
    local src="$1"
    local name=$(basename "$src")
    if [ -e "$src" ]; then
        cp -R "$src" "$OUTPUT_DIR/"
        echo "  + $name"
    else
        echo "  WARNING: $src not found"
    fi
}

copy_if_exists "$PODS_DIR/Yodo1MasFull/Yodo1MasFull/Assets/yodo1mas.plist"
copy_if_exists "$PODS_DIR/Yodo1MasCore/Yodo1MasCore/Assets/Yodo1MasCore.plist"
copy_if_exists "$PODS_DIR/Yodo1MasCore/Yodo1MasCore/Assets/Yodo1MasCore.bundle"
copy_if_exists "$PODS_DIR/Ads-Global/SDK/PAGAdSDK.bundle"
copy_if_exists "$PODS_DIR/BigoADS/BigoADS/BigoADSRes.bundle"

# ---- Dynamic Frameworks ----
echo ""
echo "[2/3] Copying dynamic frameworks..."

DYNAMIC_FRAMEWORKS=("AppLovinSDK" "InMobiSDK" "MolocoSDK" "OMSDK_Appodeal")

for fw_name in "${DYNAMIC_FRAMEWORKS[@]}"; do
    FW_PATH="$BUILD_DIR/frameworks/$fw_name.framework"
    if [ -d "$FW_PATH" ]; then
        cp -R "$FW_PATH" "$OUTPUT_DIR/frameworks/"
        echo "  + $fw_name.framework"
    else
        echo "  WARNING: $fw_name.framework not found in $BUILD_DIR/frameworks/"
    fi
done

# ---- NW Symbol Patcher ----
echo ""
echo "[3/3] Copying patch_imports.py..."

if [ -f "/tmp/patch_imports.py" ]; then
    cp "/tmp/patch_imports.py" "$OUTPUT_DIR/"
    echo "  + patch_imports.py"
elif [ -f "$SCRIPT_DIR/patch_imports.py" ]; then
    cp "$SCRIPT_DIR/patch_imports.py" "$OUTPUT_DIR/"
    echo "  + patch_imports.py"
else
    echo "  WARNING: patch_imports.py not found at /tmp/patch_imports.py or $SCRIPT_DIR/"
    echo "  You'll need to manually add it to ios_resources/ before releasing."
fi

# ---- Summary ----
echo ""
echo "============================================"
echo "  Done! Release package contents:"
echo "============================================"
echo ""
echo "ios_resources/"
ls -1 "$OUTPUT_DIR" | while read item; do
    if [ -d "$OUTPUT_DIR/$item" ]; then
        echo "├── $item/"
        ls -1 "$OUTPUT_DIR/$item" | while read sub; do
            echo "│   ├── $sub"
        done
    else
        echo "├── $item"
    fi
done

SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
echo ""
echo "Total size: $SIZE"
echo ""
echo "Include these in your GitHub Release:"
echo "  1. dest/yodo1mas.ane"
echo "  2. ios_resources/        (this directory)"
echo "  3. postprocess_ipa.sh"
