#!/bin/bash
# ============================================================
# IPA Post-Processing Script for Yodo1 MAS ANE
# ============================================================
# After ADT packages the IPA, this script performs all necessary
# post-processing steps:
#   1. Unzips the IPA
#   2. Copies SDK resource files (plists, bundles)
#   3. Embeds dynamic frameworks
#   4. Adds @executable_path/Frameworks rpath
#   5. Patches NW symbol ordinals (Network.framework fix)
#   6. Re-signs everything
#   7. Re-packages IPA
#   8. (Optionally) installs on device
#
# Usage:
#   ./postprocess_ipa.sh <input.ipa> [output.ipa]
#
# Prerequisites:
#   - codesign, install_name_tool, otool, zip
#   - /tmp/patch_imports.py (NW symbol patcher)
#   - Device certificate and entitlements
# ============================================================

set -e

# ---- Configuration ----
# Edit these to match your signing identity:
CERT="Apple Development: Faizan Abid (595ADR296X)"
ENTITLEMENTS="/tmp/ipa_entitlements.xml"
WORK_DIR="/tmp/ipa_work"

# Project paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_SRC="$SCRIPT_DIR"

# ---- Resource Discovery ----
# The script looks for iOS resources in this order:
#   1. ios_resources/ directory next to this script (release package)
#   2. ios/Pods/ + ios/build/ directories (building from source)
# End users should use the release package with ios_resources/ pre-populated.

RESOURCES_DIR="$NATIVE_SRC/ios_resources"
IOS_DIR="$NATIVE_SRC/ios"
PODS_DIR="$IOS_DIR/Pods"
BUILD_DIR="$IOS_DIR/build"

if [ -d "$RESOURCES_DIR" ]; then
    echo "Using release package resources: $RESOURCES_DIR"
    USE_RELEASE_PACKAGE=1
    PATCH_SCRIPT="$RESOURCES_DIR/patch_imports.py"
else
    echo "Using source tree resources: $IOS_DIR"
    USE_RELEASE_PACKAGE=0
    PATCH_SCRIPT="/tmp/patch_imports.py"
fi

# Dynamic frameworks that need embedding (not statically linked)
DYNAMIC_FRAMEWORKS=(
    "AppLovinSDK"
    "InMobiSDK"
    "MolocoSDK"
    "OMSDK_Appodeal"
)

# ---- Input Validation ----
INPUT_IPA="${1:-$NATIVE_SRC/demo/Yodo1MasDemo.ipa}"
OUTPUT_IPA="${2:-/tmp/Yodo1MasDemo_postprocessed.ipa}"

if [ ! -f "$INPUT_IPA" ]; then
    echo "ERROR: Input IPA not found: $INPUT_IPA"
    echo "Usage: $0 <input.ipa> [output.ipa]"
    exit 1
fi

echo "============================================"
echo "  IPA Post-Processing"
echo "============================================"
echo "Input:  $INPUT_IPA"
echo "Output: $OUTPUT_IPA"
echo ""

# ---- Step 1: Unzip IPA ----
echo "[Step 1/7] Unpacking IPA..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
unzip -qo "$INPUT_IPA" -d "$WORK_DIR"

# Find the .app directory
APP=$(find "$WORK_DIR/Payload" -name "*.app" -maxdepth 1 -type d | head -1)
if [ -z "$APP" ]; then
    echo "ERROR: No .app found in IPA"
    exit 1
fi
APP_NAME=$(basename "$APP" .app)
BINARY="$APP/$APP_NAME"
echo "  App: $APP_NAME"

# ---- Step 2: Copy SDK Resource Files ----
echo "[Step 2/7] Copying SDK resource files..."

copy_resource() {
    local name="$1"
    local release_path="$RESOURCES_DIR/$name"
    local pods_path="$2"
    local is_dir="$3"  # "dir" or "file"

    if [ "$USE_RELEASE_PACKAGE" = "1" ]; then
        if [ "$is_dir" = "dir" ] && [ -d "$release_path" ]; then
            cp -R "$release_path" "$APP/"
            echo "  + $name"
            return
        elif [ "$is_dir" != "dir" ] && [ -f "$release_path" ]; then
            cp "$release_path" "$APP/"
            echo "  + $name"
            return
        fi
    fi

    # Fallback to source tree (Pods)
    if [ "$is_dir" = "dir" ] && [ -d "$pods_path" ]; then
        cp -R "$pods_path" "$APP/"
        echo "  + $name"
    elif [ "$is_dir" != "dir" ] && [ -f "$pods_path" ]; then
        cp "$pods_path" "$APP/"
        echo "  + $name"
    else
        echo "  WARNING: $name not found"
    fi
}

# Required plists and bundles
copy_resource "yodo1mas.plist"       "$PODS_DIR/Yodo1MasFull/Yodo1MasFull/Assets/yodo1mas.plist"       "file"
copy_resource "Yodo1MasCore.plist"   "$PODS_DIR/Yodo1MasCore/Yodo1MasCore/Assets/Yodo1MasCore.plist"   "file"
copy_resource "Yodo1MasCore.bundle"  "$PODS_DIR/Yodo1MasCore/Yodo1MasCore/Assets/Yodo1MasCore.bundle"  "dir"
copy_resource "PAGAdSDK.bundle"      "$PODS_DIR/Ads-Global/SDK/PAGAdSDK.bundle"                        "dir"
copy_resource "BigoADSRes.bundle"    "$PODS_DIR/BigoADS/BigoADS/BigoADSRes.bundle"                     "dir"

# Ad network resource bundles (from built pods — source tree only)
if [ "$USE_RELEASE_PACKAGE" = "0" ]; then
    PODS_BUILD="$BUILD_DIR/pods/Release-iphoneos"
    if [ -d "$PODS_BUILD" ]; then
        for bundle_dir in "$PODS_BUILD"/*/*.bundle; do
            if [ -d "$bundle_dir" ]; then
                bundle_name=$(basename "$bundle_dir")
                cp -R "$bundle_dir" "$APP/"
                echo "  + $bundle_name"
            fi
        done
    fi
fi

# ---- Step 3: Embed Dynamic Frameworks ----
echo "[Step 3/7] Embedding dynamic frameworks..."
mkdir -p "$APP/Frameworks"

# Determine framework source directory
if [ "$USE_RELEASE_PACKAGE" = "1" ]; then
    FW_SOURCE="$RESOURCES_DIR/frameworks"
else
    FW_SOURCE="$BUILD_DIR/frameworks"
fi

for fw_name in "${DYNAMIC_FRAMEWORKS[@]}"; do
    FW_PATH="$FW_SOURCE/$fw_name.framework"
    if [ -d "$FW_PATH" ]; then
        # Check if it's actually dynamic (Mach-O type)
        if file "$FW_PATH/$fw_name" | grep -q "dynamically linked"; then
            if [ ! -d "$APP/Frameworks/$fw_name.framework" ]; then
                cp -R "$FW_PATH" "$APP/Frameworks/"
                echo "  + $fw_name.framework (dynamic)"
            else
                echo "  ~ $fw_name.framework (already present)"
            fi
        fi
    else
        echo "  WARNING: $fw_name.framework not found in $FW_SOURCE"
    fi
done

# ---- Step 4: Add rpath ----
echo "[Step 4/7] Checking rpath..."
if ! otool -l "$BINARY" 2>/dev/null | grep -A2 LC_RPATH | grep -q "@executable_path/Frameworks"; then
    install_name_tool -add_rpath @executable_path/Frameworks "$BINARY" 2>/dev/null || true
    echo "  Added @executable_path/Frameworks rpath"
else
    echo "  rpath already present"
fi

# ---- Step 5: Patch NW Symbol Ordinals ----
echo "[Step 5/7] Patching NW symbol ordinals..."
if [ -f "$PATCH_SCRIPT" ]; then
    python3 "$PATCH_SCRIPT" "$BINARY" 2>&1 | tail -5
else
    echo "  WARNING: Patch script not found at $PATCH_SCRIPT"
    echo "  NW symbols may cause a dyld crash on iOS 26+"
fi

# ---- Step 6: Re-sign ----
echo "[Step 6/7] Code signing..."

# Sign frameworks
for fw in "$APP/Frameworks/"*.framework; do
    if [ -d "$fw" ]; then
        codesign --force --sign "$CERT" "$fw" 2>/dev/null
        echo "  Signed: $(basename $fw)"
    fi
done

# Sign main app
codesign --force --sign "$CERT" --entitlements "$ENTITLEMENTS" "$APP" 2>/dev/null
echo "  Signed: $APP_NAME.app"

# Verify
codesign -vv "$APP" 2>&1 | head -2

# ---- Step 7: Repackage IPA ----
echo "[Step 7/7] Packaging IPA..."
rm -f "$OUTPUT_IPA"
cd "$WORK_DIR"
zip -qr "$OUTPUT_IPA" Payload/
cd - > /dev/null

echo ""
echo "============================================"
echo "  Post-processing complete!"
echo "============================================"
echo "Output IPA: $OUTPUT_IPA ($(du -h "$OUTPUT_IPA" | cut -f1))"
echo ""

# ---- Optional: Install on device ----
if [ "${INSTALL:-0}" = "1" ]; then
    echo "Installing on device..."
    ideviceinstaller install "$OUTPUT_IPA" 2>&1
fi
