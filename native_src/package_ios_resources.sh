#!/bin/bash
# ============================================================
# Package iOS Resources for Release
# ============================================================
# Collects everything the Yodo1 MAS SDK needs inside the .app bundle
# that ADT cannot take from the ANE:
#   - SDK plists (yodo1mas.plist, Yodo1MasCore.plist)
#   - resource / privacy-manifest bundles (*.bundle)
#   - the 4 dynamic frameworks, under Frameworks/
#
# The output folder mirrors the .app root, so app developers add it to
# their ADT command with:   -C ios_resources .
# ADT then copies and signs everything itself, on macOS or Windows.
# No post-processing of the IPA is needed.
#
# Run this AFTER ios/build_ios.sh.
#
# Usage:
#   cd native_src
#   ./package_ios_resources.sh
# ============================================================

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/ios/build"
OUTPUT_DIR="$SCRIPT_DIR/ios_resources"

# Dynamic frameworks (everything else in the ANE is statically linked)
DYNAMIC_FRAMEWORKS=("AppLovinSDK" "InMobiSDK" "MolocoSDK" "OMSDK_Appodeal")

if [ ! -d "$BUILD_DIR/resources" ]; then
    echo "ERROR: $BUILD_DIR/resources not found. Run ios/build_ios.sh first." >&2
    exit 1
fi

echo "============================================"
echo "  Packaging iOS Resources for Release"
echo "============================================"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/Frameworks"

echo ""
echo "[1/2] SDK plists and bundles..."
cp -R "$BUILD_DIR/resources/"* "$OUTPUT_DIR/"
ls -1 "$BUILD_DIR/resources" | sed 's/^/  + /'

echo ""
echo "[2/2] Dynamic frameworks..."
for fw_name in "${DYNAMIC_FRAMEWORKS[@]}"; do
    FW_PATH="$BUILD_DIR/frameworks/$fw_name.framework"
    if [ ! -f "$FW_PATH/$fw_name" ]; then
        echo "ERROR: $FW_PATH not found" >&2
        exit 1
    fi
    if ! file "$FW_PATH/$fw_name" | grep -q "dynamically linked"; then
        echo "ERROR: $fw_name.framework is not a dynamic framework" >&2
        exit 1
    fi
    cp -R "$FW_PATH" "$OUTPUT_DIR/Frameworks/"
    # Headers/Modules are not needed at runtime and only bloat the IPA
    rm -rf "$OUTPUT_DIR/Frameworks/$fw_name.framework/Headers" \
           "$OUTPUT_DIR/Frameworks/$fw_name.framework/Modules"
    # Strip any signature from the vendor build; ADT signs the app's frameworks
    rm -rf "$OUTPUT_DIR/Frameworks/$fw_name.framework/_CodeSignature"
    echo "  + Frameworks/$fw_name.framework"
done

# Drop macOS metadata that would otherwise end up in the IPA
find "$OUTPUT_DIR" -name ".DS_Store" -delete

# Zip for the GitHub release
(cd "$SCRIPT_DIR" && rm -f ios_resources.zip && zip -qry ios_resources.zip ios_resources)

SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
echo ""
echo "============================================"
echo "  Done: $OUTPUT_DIR ($SIZE)"
echo "        $SCRIPT_DIR/ios_resources.zip"
echo "============================================"
echo "Attach to the GitHub release:"
echo "  1. dest/yodo1mas.ane"
echo "  2. ios_resources.zip"
