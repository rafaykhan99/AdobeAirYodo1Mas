#!/bin/bash
# Make all frameworks universal (arm64 + x86_64) by combining device + simulator slices
set -e
cd "$(dirname "$0")"

echo "Making frameworks universal..."
count=0
skip=0
fail=0

for fw in build/frameworks/*.framework; do
    name=$(basename "$fw" .framework)
    binary="$fw/$name"
    
    if [ ! -f "$binary" ]; then
        continue
    fi
    
    # Check if already universal
    archs=$(lipo -info "$binary" 2>/dev/null || echo "")
    if echo "$archs" | grep -q "x86_64"; then
        skip=$((skip + 1))
        continue
    fi
    
    # Find the simulator slice from xcframeworks
    sim_fw=$(find Pods -path "*ios-arm64_x86_64-simulator*/$name.framework/$name" 2>/dev/null | head -1)
    
    if [ -n "$sim_fw" ] && [ -f "$sim_fw" ]; then
        if lipo -create "$binary" "$sim_fw" -output "${binary}_fat" 2>/dev/null; then
            mv "${binary}_fat" "$binary"
            echo "  Universal: $name"
            count=$((count + 1))
        else
            echo "  LIPO FAIL: $name"
            fail=$((fail + 1))
        fi
    else
        echo "  No sim: $name"
        fail=$((fail + 1))
    fi
done

echo ""
echo "Results: $count made universal, $skip already universal, $fail arm64-only"
