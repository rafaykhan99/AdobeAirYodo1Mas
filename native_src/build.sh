#!/bin/bash
# ============================================================
# Yodo1 MAS ANE Build Script
# ============================================================
# This script builds the complete ANE from source:
#   1. Builds the Android native library (JAR) via Gradle
#   2. Compiles the ActionScript SWC library
#   3. Collects dependencies
#   4. Packages everything into the .ane file
#
# Prerequisites:
#   - AIR SDK installed (set AIR_SDK_PATH in build.properties)
#   - Android SDK installed (ANDROID_HOME set)
#   - Java 17 installed (required by Gradle 7.5.1)
#   - Apache Ant installed (for ANE packaging)
#
# Usage:
#   chmod +x build.sh
#   ./build.sh
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "  Yodo1 MAS ANE Build"
echo "============================================"

# Load build properties
# First pass: load simple key=value pairs
eval $(grep -v '^\s*#' build.properties | grep -v '^\s*$' | sed 's/ *= */=/' | sed 's/\${/\$\{/g')
# Re-evaluate to resolve ${VAR} references
eval "FRE_JAR=${FRE_JAR}"
eval "ADT_JAR=${ADT_JAR}"
eval "ANE_PATH=${ANE_PATH}"
eval "SWC_PATH=${SWC_PATH}"

# Detect Java 17 for Gradle (Gradle 7.5.1 requires Java 11-17)
if command -v /usr/libexec/java_home &> /dev/null; then
    JAVA17_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || true)
    if [ -n "$JAVA17_HOME" ]; then
        export JAVA_HOME="$JAVA17_HOME"
        echo "Using Java 17: $JAVA_HOME"
    fi
fi

# Step 1: Build Android native library and collect dependencies
echo ""
echo "[Step 1/4] Building Android native library..."
echo "--------------------------------------------"
cd Yodo1MasAndroidProject

if [ -f "gradlew" ]; then
    chmod +x gradlew
    ./gradlew yodo1mas_lib:assembleRelease yodo1mas_lib:collectDependencies
else
    echo "ERROR: gradlew not found. Run: gradle wrapper --gradle-version 7.5.1"
    exit 1
fi

cd "$SCRIPT_DIR"

# Step 2: Copy FlashRuntimeExtensions.jar to Android project libs
echo ""
echo "[Step 2/4] Setting up FRE JAR..."
echo "--------------------------------------------"
if [ ! -f "$FRE_JAR" ]; then
    echo "WARNING: FlashRuntimeExtensions.jar not found at: $FRE_JAR"
    echo "Update AIR_SDK_PATH in build.properties to point to your AIR SDK"
fi

# Step 3: Compile ActionScript SWC
echo ""
echo "[Step 3/4] Compiling ActionScript SWC library..."
echo "--------------------------------------------"
COMPC="${AIR_SDK_PATH}/bin/compc"
if [ -f "$COMPC" ]; then
    mkdir -p as/bin
    "$COMPC" \
        -source-path as/src \
        -include-classes com.AdobeAir.Yodo1Mas.Yodo1Mas com.AdobeAir.Yodo1Mas.Yodo1MasEvent com.AdobeAir.Yodo1Mas.Yodo1MasBannerPosition com.AdobeAir.Yodo1Mas.Yodo1MasFunNames \
        -external-library-path "${AIR_SDK_PATH}/frameworks/libs/air/airglobal.swc" \
        -output as/bin/yodo1mas.swc
    echo "SWC compiled successfully: as/bin/yodo1mas.swc"
else
    echo "WARNING: compc not found at: $COMPC"
    echo "Update AIR_SDK_PATH in build.properties"
fi

# Step 4: Package ANE
echo ""
echo "[Step 4/4] Packaging ANE..."
echo "--------------------------------------------"
if command -v ant &> /dev/null; then
    ant
else
    echo "WARNING: Apache Ant not found. Install it or run the ant build target manually."
    echo "brew install ant  (on macOS)"
fi

echo ""
echo "============================================"
echo "  Build complete!"
echo "============================================"
echo "ANE should be at: dest/yodo1mas.ane"
echo "Demo copy at:     demo/anes/yodo1mas.ane"
