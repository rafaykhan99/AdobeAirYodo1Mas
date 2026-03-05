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

# ---- Step 4: Collect frameworks ----
echo ""
echo "[Step 4/4] Collecting Yodo1 MAS SDK frameworks..."
echo "---------------------------------------------------"

# Copy frameworks from Pods build output
PODS_BUILD="Pods/build"
if [ -d "$PODS_BUILD" ]; then
    find "$PODS_BUILD" -name "*.framework" -exec cp -R {} "$BUILD_DIR/frameworks/" \;
fi

# Also copy from the Pods directory structure
PODS_DIR="Pods"
if [ -d "$PODS_DIR" ]; then
    find "$PODS_DIR" -path "*/ios-arm64*/*.framework" -exec cp -R {} "$BUILD_DIR/frameworks/" \; 2>/dev/null || true
    find "$PODS_DIR" -path "*/*.xcframework/ios-arm64*/*.framework" -exec cp -R {} "$BUILD_DIR/frameworks/" \; 2>/dev/null || true
    # Copy vendored frameworks from pod specs
    find "$PODS_DIR" -name "*.framework" -not -path "*/Headers/*" -not -path "*/build/*" -exec cp -R {} "$BUILD_DIR/frameworks/" \; 2>/dev/null || true
fi

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
