# iOS Integration Guide — Yodo1 MAS ANE

This guide walks you through integrating the Yodo1 MAS ANE into your Adobe AIR game for iOS. You do **not** need to build the ANE from source — just use the pre-built release package.

---

## What You Need

1. **The release package** (download from [Releases](../../releases)):
   - `yodo1mas.ane` — the native extension
   - `ios_resources/` — iOS SDK resource files, dynamic frameworks, and tools
   - `postprocess_ipa.sh` — one-click IPA post-processing script

2. **On your Mac:**
   - macOS with Xcode command line tools (`xcode-select --install`)
   - [AIR SDK](https://airsdk.harman.com/download) 51.x+
   - Python 3 (pre-installed on macOS)
   - Apple Development certificate + provisioning profile (from [Apple Developer](https://developer.apple.com))
   - `libimobiledevice` for on-device install: `brew install libimobiledevice ideviceinstaller`

3. **From the [Yodo1 MAS Dashboard](https://mas.yodo1.com/):**
   - Your **App Key**
   - Your **AdMob App ID**

> **No Xcode project, no CocoaPods, no `pod install`.** Everything the SDK needs is already included in the release package.

---

## Integration Steps

### Step 1: Add the ANE to Your Project

1. Copy `yodo1mas.ane` into your project's ANE directory (e.g., `anes/`).

2. Add the extension to your `*-app.xml`:
   ```xml
   <extensions>
       <extensionID>com.AdobeAir.Yodo1Mas</extensionID>
   </extensions>
   ```

### Step 2: Configure Your App Descriptor

Add the `<iPhone>` section to your `*-app.xml`:

```xml
<iPhone>
    <InfoAdditions><![CDATA[
        <key>MinimumOSVersion</key>
        <string>14.0</string>
        <key>UIDeviceFamily</key>
        <array>
            <string>1</string>
            <string>2</string>
        </array>

        <!-- REQUIRED: Your AdMob App ID from the Yodo1 MAS Dashboard -->
        <key>GADApplicationIdentifier</key>
        <string>YOUR_ADMOB_APP_ID</string>

        <!-- REQUIRED: App Tracking Transparency prompt text (iOS 14+) -->
        <key>NSUserTrackingUsageDescription</key>
        <string>This identifier will be used to deliver personalized ads to you.</string>

        <!-- Allow ad network HTTP requests -->
        <key>NSAppTransportSecurity</key>
        <dict>
            <key>NSAllowsArbitraryLoads</key>
            <true/>
        </dict>
    ]]></InfoAdditions>
    <requestedDisplayResolution>high</requestedDisplayResolution>
</iPhone>
```

> Replace `YOUR_ADMOB_APP_ID` with your actual AdMob ID (e.g., `ca-app-pub-5580537606944457~5621171343`).

### Step 3: Use the ActionScript API

The API is identical on iOS and Android — no platform-specific code needed:

```actionscript
import com.AdobeAir.Yodo1Mas.Yodo1Mas;
import com.AdobeAir.Yodo1Mas.Yodo1MasEvent;

var mas:Yodo1Mas = Yodo1Mas.getInstance();

// Set privacy flags before init
mas.setCOPPA(false);
mas.setGDPR(true);
mas.setCCPA(false);

// Listen for init
mas.addEventListener(Yodo1MasEvent.SDK_INIT_SUCCESS, function(e:Yodo1MasEvent):void {
    trace("SDK ready!");
    mas.loadBannerAd();
    mas.loadInterstitialAd();
    mas.loadRewardedAd();
});

// Initialize with your app key
mas.initSdk("YourAppKey");
```

See the [main README](../../README.md) for the full API reference (banner, interstitial, rewarded, app open ads).

### Step 4: Build the IPA with ADT

```bash
java -jar $AIR_SDK_PATH/lib/adt.jar \
    -package -target ipa-debug \
    -provisioning-profile /path/to/your.mobileprovision \
    -storetype pkcs12 -keystore cert.p12 -storepass YOUR_PASSWORD \
    MyGame.ipa \
    MyGame-app.xml \
    MyGame.swf \
    -extdir anes
```

> You will see many "symbol not found" warnings during compilation — this is normal. The symbols come from system libraries that iOS provides at runtime. The build will succeed with exit code 0.

### Step 5: Post-Process the IPA (one command)

The IPA from ADT is missing a few things the SDK needs at runtime. The `postprocess_ipa.sh` script fixes everything automatically:

```bash
./postprocess_ipa.sh MyGame.ipa
```

**Before running**, edit the configuration at the top of `postprocess_ipa.sh`:

```bash
# Your Apple Development certificate name (find it with: security find-identity -v -p codesigning)
CERT="Apple Development: Your Name (XXXXXXXXXX)"

# Path to your entitlements file
ENTITLEMENTS="/path/to/entitlements.plist"
```

**Create the entitlements file** (one time):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>application-identifier</key>
    <string>TEAMID.com.yourcompany.yourgame</string>
    <key>get-task-allow</key>
    <true/>
</dict>
</plist>
```

> Replace `TEAMID` with your Apple Team ID and the bundle ID with yours. Find your Team ID in your provisioning profile or Apple Developer portal.

The script outputs a fixed IPA (e.g., `MyGame_postprocessed.ipa`).

### Step 6: Install and Test

```bash
# Install on a connected device
ideviceinstaller install MyGame_postprocessed.ipa
```

That's it! The SDK will initialize when your game calls `initSdk()`.

---

## What the Post-Processing Script Does

You don't need to understand these details to integrate — the script handles them. This section explains what it automates and why, in case you need to debug.

| What | Why |
|------|-----|
| Copies `yodo1mas.plist`, `Yodo1MasCore.plist`, `Yodo1MasCore.bundle` | The SDK loads version info from these at startup. Without them, the SDK crashes with `NSInvalidArgumentException`. |
| Copies `PAGAdSDK.bundle` | The Pangle (ByteDance) ad network validates its version at init. Missing bundle = crash. |
| Copies `BigoADSRes.bundle` | BigoADS ad network resources. |
| Embeds 4 dynamic frameworks into `Frameworks/` | AppLovinSDK, InMobiSDK, MolocoSDK, OMSDK_Appodeal are dynamically linked. ADT doesn't embed them. |
| Adds `@executable_path/Frameworks` rpath | Tells the dynamic linker where to find the embedded frameworks. |
| Patches NW symbol ordinals | Fixes an AIR SDK AOT compiler bug that binds Network.framework symbols to the wrong library. Without this, the app crashes on launch (iOS 18+). |
| Re-signs the app and frameworks | All modifications above invalidate the original code signature. |

---

## Troubleshooting

### App crashes immediately on launch
**Likely cause:** NW symbol ordinal bug (iOS 18+). The crash log will mention `dyld` and `_nw_interface_get_type`.
**Fix:** Make sure `postprocess_ipa.sh` ran successfully — check for "Patching NW symbol ordinals" in the output.

### SDK init crashes with `NSInvalidArgumentException`
**Cause:** `yodo1mas.plist` is missing from the app bundle.
**Fix:** Ensure `ios_resources/` contains the plists and the postprocess script ran. Check script output for "+ yodo1mas.plist".

### Crash shortly after init — `+[PAGAdSDKManager checkBundleVersion]`
**Cause:** `PAGAdSDK.bundle` is missing.
**Fix:** Ensure `ios_resources/` contains the bundle and the postprocess script copied it.

### `Library not loaded: @rpath/AppLovinSDK.framework/AppLovinSDK`
**Cause:** Dynamic frameworks not embedded or rpath missing.
**Fix:** Check that postprocess script output shows "+ AppLovinSDK.framework (dynamic)".

### Code signing error on install
**Cause:** Wrong certificate name or entitlements.
**Fix:**
1. List your certificates: `security find-identity -v -p codesigning`
2. Copy the exact name into `postprocess_ipa.sh`
3. Make sure the `application-identifier` in your entitlements matches `TEAMID.your.bundle.id`

### ADT build produces linker warnings
This is expected. ADT reports "symbol not found" for system symbols that exist at runtime on the device. The build still succeeds (exit code 0).

### `No matching provisioning profile found`
Your provisioning profile must match your bundle ID and be a development profile. If using a wildcard profile, ensure your Team ID matches.

---

## For ANE Developers (Building from Source)

If you need to modify the native code and rebuild the ANE, see the project source:

```
native_src/ios/
├── Podfile                     # CocoaPods (Yodo1MasFull 4.17.1)
├── build_ios.sh                # Build script
├── Yodo1MasANE.xcodeproj/     # Xcode project
└── Yodo1MasANE/               # Obj-C source (Yodo1MasANE.m, Yodo1MasBridge.m)
```

```bash
cd native_src/ios
pod install --repo-update    # Only needed when building from source
./build_ios.sh               # Produces libYodo1MasANE.a + collects frameworks
cd ..
./build.sh                   # Packages the full ANE
```

### ANE packaging fails for iPhone-ARM
Ensure `ios/build/libYodo1MasANE.a` exists and the `ios/build/frameworks/` directory contains the required `.framework` bundles.

### Ads not showing on device
1. Check that your Yodo1 app key is correct
2. Verify Info.plist has `GADApplicationIdentifier` and `NSAppTransportSecurity`
3. Check device console logs for `Yodo1MasANE` tagged messages
4. Ensure you're calling `setCOPPA`/`setGDPR`/`setCCPA` before `initSdk()`

---

## Quick Reference: Complete Build & Deploy

```bash
# 1. Build native lib + ANE
cd native_src/ios && ./build_ios.sh && cd ..
ant compile

# 2. Compile demo SWF (update APP_KEY in Yodo1MasDemo.as first!)
$AIR_SDK_PATH/bin/mxmlc \
    -source-path demo/src \
    -library-path+=as/bin/yodo1mas.swc \
    -output demo/Yodo1MasDemo.swf \
    demo/src/Yodo1MasDemo.as

# 3. Package IPA with ADT
cd demo
java -jar $AIR_SDK_PATH/lib/adt.jar \
    -package -target ipa-debug \
    -provisioning-profile /path/to/profile.mobileprovision \
    -storetype pkcs12 -keystore cert.p12 -storepass PASSWORD \
    /tmp/output.ipa \
    Yodo1MasDemo-app.xml Yodo1MasDemo.swf \
    -extdir anes

# 4. Post-process (resource files, frameworks, NW patch, re-sign)
cd ..
./postprocess_ipa.sh /tmp/output.ipa

# 5. Install
ideviceinstaller install /tmp/Yodo1MasDemo_postprocessed.ipa
```

---

## References

- [Yodo1 MAS iOS Integration Guide](https://developers.yodo1.com/docs/sdk/guides/ios/integration)
- [Yodo1 MAS iOS Ad Formats](https://developers.yodo1.com/docs/sdk/guides/ios/ad-formats)
- [SKAdNetwork IDs](https://developers.yodo1.com/docs/sdk/getting_started/configure/ios#advertising-network-id)
