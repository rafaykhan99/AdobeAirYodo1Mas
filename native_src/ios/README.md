# iOS Integration Guide — Yodo1 MAS ANE

This guide covers integrating the Yodo1 MAS ANE into an Adobe AIR game for iOS. You do **not** need to build the ANE from source; use the release files.

**Works on Windows and macOS.** The iOS build is a normal ADT build: one command produces a finished, signed IPA. No Xcode, no CocoaPods, no post-processing.

---

## What You Need

1. **From the [Releases](https://github.com/rafaykhan99/AdobeAirYodo1Mas/releases) page:**
   - `yodo1mas.ane`: the native extension
   - `ios_resources.zip`: files the SDK needs inside the app bundle (SDK plists, ad-network resource / privacy-manifest bundles, 4 dynamic frameworks)

2. **On your build machine (Windows or macOS):**
   - [AIR SDK](https://airsdk.harman.com/download) 51.x+
   - Your usual AIR iOS signing files: a `.p12` certificate and a matching `.mobileprovision`
     (development for device testing, distribution + App Store profile for TestFlight / App Store)

3. **From the [Yodo1 MAS Dashboard](https://mas.yodo1.com/):**
   - Your **App Key**
   - Your **AdMob App ID**

---

## Integration Steps

### Step 1: Add the ANE

1. Copy `yodo1mas.ane` into your project's ANE directory (e.g. `anes/`).
2. Add the extension to your `*-app.xml`:
   ```xml
   <extensions>
       <extensionID>com.AdobeAir.Yodo1Mas</extensionID>
   </extensions>
   ```

### Step 2: Add the iOS resources

Unzip `ios_resources.zip` next to your project. You get an `ios_resources/` folder whose contents go at the **root of the app bundle**:

```
ios_resources/
├── yodo1mas.plist, Yodo1MasCore.plist     SDK configuration (SDK init crashes without them)
├── *.bundle                               ad-network resources + privacy manifests
└── Frameworks/                            AppLovinSDK, InMobiSDK, MolocoSDK, OMSDK_Appodeal
```

### Step 3: Configure Your App Descriptor

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

The bundle ID (`<id>`) must match the app registered in the MAS Dashboard, otherwise SDK init fails with `-400001 Bundle ID not match`.

### Step 4: Use the ActionScript API

The API is identical on iOS and Android:

```actionscript
import com.AdobeAir.Yodo1Mas.Yodo1Mas;
import com.AdobeAir.Yodo1Mas.Yodo1MasEvent;

var mas:Yodo1Mas = Yodo1Mas.getInstance();

// Set privacy flags before init
mas.setCOPPA(false);
mas.setGDPR(true);
mas.setCCPA(false);

mas.addEventListener(Yodo1MasEvent.SDK_INIT_SUCCESS, function(e:Yodo1MasEvent):void {
    mas.loadBannerAd();
    mas.loadInterstitialAd();
    mas.loadRewardedAd();
});

mas.initSdk("YourAppKey");
```

See the [main README](../../README.md) for the full API reference.

### Step 5: Build the IPA

Add `-C ios_resources .` to your usual ADT command. The trailing `.` places the folder's *contents* at the app root.

**App Store / TestFlight:**

```bash
adt -package -target ipa-app-store \
    -provisioning-profile MyGame_AppStore.mobileprovision \
    -storetype pkcs12 -keystore distribution.p12 -storepass PASSWORD \
    MyGame.ipa MyGame-app.xml MyGame.swf \
    -C ios_resources . \
    -extdir anes
```

**Device test build:** same command with `-target ipa-debug` (or `ipa-test`), your development `.p12` and development profile.

On Windows use `^` instead of `\` for line continuation (or put it on one line).

The IPA ADT produces is final: ADT copies the resources, embeds the dynamic frameworks and signs everything. Upload it as usual (Transporter on a Mac, or any other upload route), or install a test build with Xcode's Devices window, Apple Configurator, or `ideviceinstaller`.

> **Using an IDE** (Animate, FlashDevelop, IntelliJ, VS Code AS3 extension...): add every item inside `ios_resources/` (the two `.plist` files, the `.bundle` folders and the `Frameworks` folder) to the iOS package's included files, at the root of the app. Do not add the `ios_resources` folder itself.

> Linker warnings during packaging (duplicate `AES_*` symbols, ObjC category method conflicts) are expected and harmless.

---

## Troubleshooting

### SDK init fails with `-400001 Bundle ID not match`
The app's `<id>` differs from the bundle ID registered for your App Key in the MAS Dashboard.

### SDK init crashes with `NSInvalidArgumentException`
`yodo1mas.plist` / `Yodo1MasCore.plist` are missing from the app. Check that `-C ios_resources .` is in your ADT command (with the trailing `.`), or that your IDE includes the plists at the app root.

### Crash shortly after init — `+[PAGAdSDKManager checkBundleVersion]`
`PAGAdSDK.bundle` is missing from the app root (same cause as above).

### `Library not loaded: @rpath/AppLovinSDK.framework/AppLovinSDK`
The `Frameworks/` folder from `ios_resources` is not in the app. It must end up as `Frameworks/` at the app root.

### ADT: `library not found for -l...` or `Undefined symbols`
You are using an old `yodo1mas.ane` (v1.0.2 or earlier needed files that only existed on the original developer's machine). Use the latest release.

### App Store Connect warns about missing privacy manifests
Make sure all `.bundle` folders from `ios_resources` are included; most of them carry the SDKs' `PrivacyInfo.xcprivacy`.

### Ads not showing on device
1. Check your App Key and that the bundle ID matches the dashboard
2. Verify Info.plist has `GADApplicationIdentifier` and `NSAppTransportSecurity`
3. Check device console logs for `Yodo1MasANE` / `[Yodo1Mas]` messages
4. Call `setCOPPA` / `setGDPR` / `setCCPA` before `initSdk()`

---

## For ANE Developers (Building from Source)

Requires macOS with Xcode 16+ (tested with 26.6), CocoaPods and a **stock** AIR SDK.

```bash
cd native_src
./build.sh            # Android + iOS + SWC + ANE + ios_resources
# Outputs: dest/yodo1mas.ane, ios_resources/, ios_resources.zip
```

iOS-only pieces:

```
native_src/ios/
├── Podfile                     # CocoaPods (Yodo1MasFull 4.17.1) + Xcode 26 AFNetworking fix
├── build_ios.sh                # Builds libYodo1MasANE.a, libYodo1MasLinkFixes.a, collects frameworks/resources
├── stubs/                      # Link fixes for the AIR SDK's old system stubs (see main README)
├── Yodo1MasANE.xcodeproj/
└── Yodo1MasANE/                # Obj-C source (Yodo1MasANE.m, Yodo1MasBridge.m)
native_src/package_ios_resources.sh   # ios/build/resources + dynamic frameworks -> ios_resources/
native_src/tools/check_ios_binds.py   # Check an IPA's imports against the real iOS SDK
```

Release checklist: attach both `dest/yodo1mas.ane` and `ios_resources.zip` to the GitHub release.

---

## References

- [Yodo1 MAS iOS Integration Guide](https://developers.yodo1.com/docs/sdk/guides/ios/integration)
- [Yodo1 MAS iOS Ad Formats](https://developers.yodo1.com/docs/sdk/guides/ios/ad-formats)
- [SKAdNetwork IDs](https://developers.yodo1.com/docs/sdk/getting_started/configure/ios#advertising-network-id)
