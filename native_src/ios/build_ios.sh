#!/bin/bash
# ============================================================
# Yodo1 MAS ANE — iOS Build Script
# ============================================================
# This script builds the iOS static library for the ANE:
#   1. Installs CocoaPods dependencies (Yodo1MasFull)
#   2. Copies FlashRuntimeExtensions.h from AIR SDK
#   3. Compiles the native Objective-C code into libYodo1MasANE.a
#      for both arm64 (device)
#   4. Collects the .framework bundles from Pods
#
# Prerequisites:
#   - Xcode 16+ installed with command line tools
#   - CocoaPods installed (gem install cocoapods)
#   - AIR SDK installed (set AIR_SDK_PATH in ../build.properties)
#
# Usage:
#   cd native_src/ios
#   chmod +x build_ios.sh
#   ./build_ios.sh
#
# Output:
#   build/libYodo1MasANE.a       — Universal static library
#   build/frameworks/             — Yodo1 MAS SDK & adapter frameworks
# ============================================================

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Load build properties from parent
PROPS_FILE="../build.properties"
if [ -f "$PROPS_FILE" ]; then
    eval $(grep -v '^\s*#' "$PROPS_FILE" | grep -v '^\s*$' | sed 's/ *= */=/')
fi

echo "============================================"
echo "  Yodo1 MAS ANE — iOS Build"
echo "============================================"

# ---- Step 1: Install CocoaPods ----
echo ""
echo "[Step 1/4] Installing CocoaPods dependencies..."
echo "------------------------------------------------"
if [ ! -f "Podfile" ]; then
    echo "ERROR: Podfile not found in $(pwd)"
    exit 1
fi

pod install --repo-update

# ---- Step 2: Copy FlashRuntimeExtensions.h ----
echo ""
echo "[Step 2/4] Copying FlashRuntimeExtensions.h from AIR SDK..."
echo "------------------------------------------------------------"
FRE_HEADER="${AIR_SDK_PATH}/include/FlashRuntimeExtensions.h"
if [ -f "$FRE_HEADER" ]; then
    cp "$FRE_HEADER" Yodo1MasANE/FlashRuntimeExtensions.h
    echo "Copied FlashRuntimeExtensions.h"
else
    echo "WARNING: FlashRuntimeExtensions.h not found at: $FRE_HEADER"
    echo "Make sure AIR_SDK_PATH is set correctly in build.properties"
    echo "Looking for alternative locations..."
    
    # Try common alternative paths
    ALT_PATHS=(
        "${AIR_SDK_PATH}/include/FlashRuntimeExtensions.h"
        "${AIR_SDK_PATH}/lib/ios/FlashRuntimeExtensions.h"
    )
    FOUND=false
    for ALT in "${ALT_PATHS[@]}"; do
        if [ -f "$ALT" ]; then
            cp "$ALT" Yodo1MasANE/FlashRuntimeExtensions.h
            echo "Found and copied from: $ALT"
            FOUND=true
            break
        fi
    done
    
    if [ "$FOUND" = false ] && [ ! -f "Yodo1MasANE/FlashRuntimeExtensions.h" ]; then
        echo "ERROR: Cannot find FlashRuntimeExtensions.h. Build will fail."
        echo "Please copy it manually to: $(pwd)/Yodo1MasANE/FlashRuntimeExtensions.h"
        exit 1
    fi
fi

# ---- Step 3: Build static library ----
echo ""
echo "[Step 3/4] Building iOS static library..."
echo "-------------------------------------------"

BUILD_DIR="$SCRIPT_DIR/build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$BUILD_DIR/frameworks"

# Determine Pods xcconfig for header search paths
PODS_XCCONFIG=""
if [ -f "Pods/Target Support Files/Pods-Yodo1MasANE/Pods-Yodo1MasANE.release.xcconfig" ]; then
    PODS_XCCONFIG="Pods/Target Support Files/Pods-Yodo1MasANE/Pods-Yodo1MasANE.release.xcconfig"
fi

# Build for arm64 (device)
echo "Building for arm64 (device)..."
xcodebuild \
    -workspace Yodo1MasANE.xcworkspace \
    -scheme Yodo1MasANE \
    -configuration Release \
    -sdk iphoneos \
    -arch arm64 \
    CONFIGURATION_BUILD_DIR="$BUILD_DIR/arm64" \
    HEADER_SEARCH_PATHS="\$(inherited) $SCRIPT_DIR/Yodo1MasANE $SCRIPT_DIR/Pods/Headers/Public $SCRIPT_DIR/Pods/Headers/Public/Yodo1MasCore" \
    ONLY_ACTIVE_ARCH=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    clean build 2>&1 | tail -20

# Copy the arm64 build as the final library (device-only for ANE)
cp "$BUILD_DIR/arm64/libYodo1MasANE.a" "$BUILD_DIR/libYodo1MasANE.a"

echo "Static library built: $BUILD_DIR/libYodo1MasANE.a"

# Verify
lipo -info "$BUILD_DIR/libYodo1MasANE.a"

# ---- Step 4: Collect frameworks, stubs and resources ----
echo ""
echo "[Step 4/4] Collecting Yodo1 MAS SDK frameworks, stubs and resources..."
echo "---------------------------------------------------------------------"

PODS_DIR="Pods"
SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"

# 4a. Vendored frameworks (device slices only; never copy simulator slices,
#     they share the folder name and would overwrite the device build).
find "$PODS_DIR" -name "*.framework" -type d \
    -not -path "*/Headers/*" -not -path "*simulator*" -not -path "*.framework/*" \
    -print0 | while IFS= read -r -d '' fw; do
        cp -R "$fw" "$BUILD_DIR/frameworks/"
    done

# 4b. Source pods (AFNetworking, YDYThinkingSDK, YYModel) are compiled by
#     xcodebuild into static frameworks under build/arm64.
for fw in AFNetworking YDYThinkingSDK YYModel; do
    if [ -d "$BUILD_DIR/arm64/$fw.framework" ]; then
        rm -rf "$BUILD_DIR/frameworks/$fw.framework"
        cp -R "$BUILD_DIR/arm64/$fw.framework" "$BUILD_DIR/frameworks/"
    else
        echo "ERROR: $fw.framework was not built" >&2
        exit 1
    fi
done

# 4c. Link-fix library + link-time stub frameworks (sources in stubs/; see the
#     comments in stubs/Yodo1MasLinkFixes.c and stubs/*.framework/*)
xcrun clang -target arm64-apple-ios13.0 -isysroot "$SDK_PATH" -O2 \
    -c stubs/Yodo1MasLinkFixes.c -o "$BUILD_DIR/Yodo1MasLinkFixes.o"
rm -f "$BUILD_DIR/libYodo1MasLinkFixes.a"
xcrun libtool -static -o "$BUILD_DIR/libYodo1MasLinkFixes.a" "$BUILD_DIR/Yodo1MasLinkFixes.o"
rm -f "$BUILD_DIR/Yodo1MasLinkFixes.o"
for fw in stubs/*.framework; do
    rm -rf "$BUILD_DIR/frameworks/$(basename "$fw")"
    cp -R "$fw" "$BUILD_DIR/frameworks/"
done

# 4d. Runtime resources that must sit in the .app root: SDK plists and
#     resource / privacy-manifest bundles. Collected into build/resources and
#     shipped to app developers as ios_resources/ (see package_ios_resources.sh).
RES_DIR="$BUILD_DIR/resources"
rm -rf "$RES_DIR"; mkdir -p "$RES_DIR"
cp "$PODS_DIR/Yodo1MasFull/Yodo1MasFull/Assets/yodo1mas.plist"     "$RES_DIR/"
cp "$PODS_DIR/Yodo1MasCore/Yodo1MasCore/Assets/Yodo1MasCore.plist" "$RES_DIR/"
cp -R "$PODS_DIR/Yodo1MasCore/Yodo1MasCore/Assets/Yodo1MasCore.bundle" "$RES_DIR/"
cp -R "$PODS_DIR/Ads-Global/SDK/PAGAdSDK.bundle"    "$RES_DIR/"
cp -R "$PODS_DIR/BigoADS/BigoADS/BigoADSRes.bundle" "$RES_DIR/"
# Resource bundles generated by pod resource_bundle targets
for b in "$BUILD_DIR"/arm64/*.bundle; do
    [ -d "$b" ] && cp -R "$b" "$RES_DIR/"
done

echo ""
echo "============================================"
echo "  iOS Build Complete!"
echo "============================================"
echo "  Library:    $BUILD_DIR/libYodo1MasANE.a"
echo "  Frameworks: $BUILD_DIR/frameworks/"
echo ""
echo "  Frameworks collected:"
ls -1 "$BUILD_DIR/frameworks/" 2>/dev/null || echo "  (none found — may need manual collection)"
echo ""
echo "  Next: Run the main build.sh to package the ANE"
echo "============================================"
