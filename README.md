# Yodo1 MAS Adobe AIR Native Extension (ANE)

Yodo1 MAS (Mediation Ad SDK) plugin for Adobe AIR, supporting **Android** and **iOS**.

This ANE wraps the [Yodo1 MAS SDK 4.17.1](https://developers.yodo1.com/) for use in Adobe AIR / ActionScript 3 projects, providing access to multiple ad networks (AdMob, AppLovin, Unity Ads, Vungle, Mintegral, InMobi, Fyber, Bigo, Pangle, and more) through a single integration.

## Supported Ad Formats

| Format | Android | iOS |
|--------|---------|-----|
| Banner | ✅ | ✅ |
| Interstitial | ✅ | ✅ |
| Rewarded Video | ✅ | ✅ |
| App Open | ✅ | ✅ |

---

## Integration Guide

### Prerequisites

- **AIR SDK** 51.x+ ([Download](https://airsdk.harman.com/download))
- A [Yodo1 MAS Dashboard](https://mas.yodo1.com/) account with your app registered
- Your **Yodo1 App Key** and **AdMob App ID** (found in the MAS Dashboard)

**Platform-specific:**

| | Android | iOS |
|---|---------|-----|
| OS | Windows / macOS / Linux | **Windows or macOS** |
| Tools | Android SDK (platform 36, build-tools 36+), Java JDK 17 | Nothing beyond the AIR SDK (no Xcode needed) |
| Signing | PKCS12 certificate (`.p12`) | Your usual AIR iOS signing: `.p12` + `.mobileprovision` |
| Release files | `yodo1mas.ane` | `yodo1mas.ane` + `ios_resources.zip` |

> **iOS builds work exactly like any other AIR iOS build**, on Windows or macOS: one ADT command produces a finished, signed IPA. There is no post-processing step, no Xcode project, no CocoaPods.

### Step 1: Add the ANE to Your Project

1. Copy `yodo1mas.ane` into your project's ANE directory (e.g., `anes/`).

2. Add the ANE to your IDE's build path or ADT command:
   ```
   -extdir anes
   ```

3. Add the extension ID to your AIR application descriptor (`*-app.xml`):
   ```xml
   <extensions>
       <extensionID>com.AdobeAir.Yodo1Mas</extensionID>
   </extensions>
   ```

### Step 2: Configure Your App Descriptor

Add the following Android manifest entries to your `*-app.xml`.

```xml
<android>
    <manifestAdditions><![CDATA[
        <manifest android:installLocation="auto">
            <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="36"/>

            <!-- Required permissions -->
            <uses-permission android:name="android.permission.INTERNET"/>
            <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
            <uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>

            <application android:hardwareAccelerated="true">

                <!-- AdMob Application ID (REQUIRED) -->
                <!-- Get yours from: MAS Dashboard > Management > Games > Manage > Details -->
                <meta-data
                    android:name="com.google.android.gms.ads.APPLICATION_ID"
                    android:value="YOUR_ADMOB_APP_ID"/>

            </application>
        </manifest>
    ]]></manifestAdditions>
</android>
```

> **Important:** Replace `YOUR_ADMOB_APP_ID` with your actual AdMob Application ID from the Yodo1 MAS Dashboard. The SDK will crash on startup if this is missing.
>
> **Note:** The AppLovin SDK key is already hardcoded in the ANE — you do not need to add it.

### Step 3 (iOS): Configure iOS and Build the IPA

**3a.** Download `ios_resources.zip` from the same [release](../../releases) as the ANE and unzip it next to your project. It contains files the SDK needs inside the app bundle that an ANE cannot deliver: SDK plists, ad-network resource / privacy-manifest bundles, and 4 dynamic frameworks (`Frameworks/`).

**3b.** Add the `<iPhone>` section to your `*-app.xml`:

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
        <!-- REQUIRED: Your AdMob App ID from Yodo1 MAS Dashboard -->
        <key>GADApplicationIdentifier</key>
        <string>YOUR_ADMOB_APP_ID</string>
        <!-- REQUIRED: App Tracking Transparency (iOS 14+) -->
        <key>NSUserTrackingUsageDescription</key>
        <string>This identifier will be used to deliver personalized ads to you.</string>
        <key>NSAppTransportSecurity</key>
        <dict>
            <key>NSAllowsArbitraryLoads</key>
            <true/>
        </dict>
    ]]></InfoAdditions>
    <requestedDisplayResolution>high</requestedDisplayResolution>
</iPhone>
```

**3c.** Build with ADT as usual, adding `-C ios_resources .` (the trailing `.` matters: it places the folder's *contents* at the root of the app):

```bash
# App Store / TestFlight build (Windows or macOS)
adt -package -target ipa-app-store \
    -provisioning-profile MyGame_AppStore.mobileprovision \
    -storetype pkcs12 -keystore distribution.p12 -storepass PASSWORD \
    MyGame.ipa MyGame-app.xml MyGame.swf \
    -C ios_resources . \
    -extdir anes
```

For a device test build use `-target ipa-debug` (or `ipa-test`) with your development `.p12` and profile.

That's the whole iOS build: the IPA from ADT is final. ADT copies the resources, embeds the dynamic frameworks and signs everything itself, so you can build on Windows and only move the finished IPA to a Mac to upload it (Transporter), exactly as with any other AIR app.

> **Using an IDE** (Animate, FlashDevelop, IntelliJ, VS Code AS3 extension...): add every item inside `ios_resources/` (the `.plist` files, the `.bundle` folders and the `Frameworks` folder) to the iOS package's included files, at the root of the app - not the `ios_resources` folder itself.
>
> Linker warnings during packaging (duplicate symbols, category method conflicts) are expected and harmless.

### Step 4 (Android): Build with `android-studio` Target

Due to the large number of SDK dependencies (280+), you **must** use ADT's `android-studio` target instead of direct APK packaging. ADT generates a Gradle project; you then make a few edits and build it with Gradle.

> **Google Play requirements (checked November 2026):**
> - New apps and app updates must target **API level 36** (`android:targetSdkVersion="36"` in Step 2).
> - From **1 February 2027**, app updates must support **16 KB memory pages**. The native libraries in the ANE and in the AIR 51.1 runtime are already 16 KB aligned; the APK/AAB is packaged correctly only with **Android Gradle Plugin 8.5.1 or newer**. ADT generates AGP 8.1.1, so edit 3 below is required.

**1. Generate the Gradle project** (on Windows use `^` instead of `\`, or put it on one line):

```bash
adt -package -target android-studio \
    -storetype pkcs12 -keystore your-cert.p12 -storepass YOUR_PASSWORD \
    android_project YourApp-app.xml YourApp.swf -extdir anes
```

ADT recreates `android_project` every time, so **redo edits 2-4 after each regeneration** (keep copies of the edited files to paste back).

**2. Add a Gradle wrapper** (ADT does not create one). Copy from this repository's [`native_src/Yodo1MasAndroidProject/`](native_src/Yodo1MasAndroidProject):

| Copy | To |
|---|---|
| `gradlew`, `gradlew.bat` | `android_project/` |
| `gradle/wrapper/gradle-wrapper.jar` | `android_project/gradle/wrapper/` |

and create `android_project/gradle/wrapper/gradle-wrapper.properties`:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14.3-bin.zip
```

**3. Update the Android Gradle Plugin** (required for API 36 and 16 KB alignment). In `android_project/build.gradle`:

```groovy
classpath "com.android.tools.build:gradle:8.13.0"    // was 8.1.1
```

and replace both `jcenter()` lines with `mavenCentral()` (JCenter is retired).

**4. Sign release builds.** The generated project has no signing settings, so `bundleRelease` would produce an unsigned AAB. In `android_project/app/build.gradle`, add inside `android { ... }`:

```groovy
signingConfigs {
    release {
        storeFile file('C:/path/to/upload-key.p12')   // forward slashes, also on Windows
        storeType 'pkcs12'
        storePassword 'YOUR_PASSWORD'
        keyAlias 'YOUR_ALIAS'      // keytool -list -keystore upload-key.p12 shows it ("1" for adt -certificate keys)
        keyPassword 'YOUR_PASSWORD'
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

Use the same key as your previous releases (or your Play App Signing upload key). Debug builds need no signing settings.

**5. (Optional) Remove the `air.` prefix from the package name.** In `android_project/app/build.gradle` set `namespace` and `applicationId` without the prefix (e.g. `"com.yourcompany.yourgame"`). In `app/src/main/AndroidManifest.xml` remove the `package="..."` attribute and change `android:name=".AIRAppEntry"` to the full `android:name="air.com.yourcompany.yourgame.AIRAppEntry"`. Only do this for a new app, or one already published without the prefix.

**6. (Optional) Reduce the APK size.** The APK includes x86 / x86_64 libraries that only Android emulators use (about 45 MB). In `app/build.gradle`, inside `defaultConfig { ... }`, add `ndk { abiFilters 'arm64-v8a', 'armeabi-v7a' }` (or only `'arm64-v8a'` to save about 16 MB more). App Bundles (AAB) are split per device by Google Play anyway.

**7. Build with Java 17:**

```bat
REM Windows
cd android_project
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.x-hotspot"
REM Google Play: creates app\build\outputs\bundle\release\app-release.aab
gradlew.bat bundleRelease
REM Testing: creates app\build\outputs\apk\debug\app-debug.apk
gradlew.bat assembleDebug
```

```bash
# macOS / Linux
cd android_project
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
./gradlew bundleRelease       # Google Play
./gradlew assembleDebug       # testing
```

**8. Install a test build:** `adb install -r app/build/outputs/apk/debug/app-debug.apk`

> **Why `android-studio` target?** Direct APK packaging via ADT fails with a D8 multidex error because modern D8 versions reject the `--main-dex-list` flag for `minSdk >= 21`. The `android-studio` target generates a standard Gradle project that builds correctly.

---

## ActionScript API

### Import

```actionscript
import com.AdobeAir.Yodo1Mas.Yodo1Mas;
import com.AdobeAir.Yodo1Mas.Yodo1MasEvent;
import com.AdobeAir.Yodo1Mas.Yodo1MasBannerPosition;
```

### Initialize the SDK

```actionscript
var mas:Yodo1Mas = Yodo1Mas.getInstance();

// 1. Set privacy flags BEFORE calling initSdk (required)
mas.setCOPPA(false);   // true if user is under 13 (COPPA compliance)
mas.setGDPR(true);     // true if user has given consent (GDPR compliance)
mas.setCCPA(false);    // true if user opted out of data sale (CCPA compliance)

// 2. Listen for init result
mas.addEventListener(Yodo1MasEvent.SDK_INIT_SUCCESS, function(e:Yodo1MasEvent):void {
    trace("MAS SDK initialized! You can now load ads.");
});
mas.addEventListener(Yodo1MasEvent.SDK_INIT_FAILED, function(e:Yodo1MasEvent):void {
    trace("MAS SDK init failed: " + e.errorMessage);
});

// 3. Initialize with your App Key from the Yodo1 MAS Dashboard
mas.initSdk("YourAppKey");
```

### Banner Ads

```actionscript
// Listen for events
mas.addEventListener(Yodo1MasEvent.BANNER_AD_LOADED, onBannerLoaded);
mas.addEventListener(Yodo1MasEvent.BANNER_AD_FAILED_TO_LOAD, onBannerFailed);
mas.addEventListener(Yodo1MasEvent.BANNER_AD_OPENED, onBannerOpened);
mas.addEventListener(Yodo1MasEvent.BANNER_AD_CLOSED, onBannerClosed);

// Load a banner
mas.loadBannerAd();
// Or load with a placement name for analytics:
// mas.loadBannerAd("main_menu");

function onBannerLoaded(e:Yodo1MasEvent):void {
    // Show at bottom center (default)
    mas.showBannerAd(null, Yodo1MasBannerPosition.BOTTOM_CENTER);
}

// Available banner positions:
// Yodo1MasBannerPosition.TOP_CENTER      (0)
// Yodo1MasBannerPosition.BOTTOM_CENTER   (1)
// Yodo1MasBannerPosition.TOP_LEFT        (2)
// Yodo1MasBannerPosition.TOP_RIGHT       (3)
// Yodo1MasBannerPosition.BOTTOM_LEFT     (4)
// Yodo1MasBannerPosition.BOTTOM_RIGHT    (5)

// Hide the banner (can show again later)
mas.hideBannerAd();

// Destroy the banner completely (must load again to show)
mas.destroyBannerAd();

// Check if a banner is loaded
if (mas.isBannerAdLoaded()) {
    // banner is ready
}
```

### Interstitial Ads

```actionscript
// Listen for events
mas.addEventListener(Yodo1MasEvent.INTERSTITIAL_AD_LOADED, onInterstitialLoaded);
mas.addEventListener(Yodo1MasEvent.INTERSTITIAL_AD_FAILED_TO_LOAD, onInterstitialFailed);
mas.addEventListener(Yodo1MasEvent.INTERSTITIAL_AD_OPENED, onInterstitialOpened);
mas.addEventListener(Yodo1MasEvent.INTERSTITIAL_AD_FAILED_TO_OPEN, onInterstitialFailedToOpen);
mas.addEventListener(Yodo1MasEvent.INTERSTITIAL_AD_CLOSED, onInterstitialClosed);

// Load an interstitial
mas.loadInterstitialAd();

// Show at a natural break point (e.g., between levels)
function onLevelComplete():void {
    if (mas.isInterstitialAdLoaded()) {
        mas.showInterstitialAd();
        // Or with placement: mas.showInterstitialAd("level_complete");
    }
}

// Reload after the ad closes
function onInterstitialClosed(e:Yodo1MasEvent):void {
    mas.loadInterstitialAd(); // Pre-load the next one
}
```

### Rewarded Video Ads

```actionscript
// Listen for events
mas.addEventListener(Yodo1MasEvent.REWARDED_AD_LOADED, onRewardedLoaded);
mas.addEventListener(Yodo1MasEvent.REWARDED_AD_FAILED_TO_LOAD, onRewardedFailed);
mas.addEventListener(Yodo1MasEvent.REWARDED_AD_OPENED, onRewardedOpened);
mas.addEventListener(Yodo1MasEvent.REWARDED_AD_FAILED_TO_OPEN, onRewardedFailedToOpen);
mas.addEventListener(Yodo1MasEvent.REWARDED_AD_CLOSED, onRewardedClosed);
mas.addEventListener(Yodo1MasEvent.REWARDED_AD_EARNED, onRewardEarned);

// Pre-load a rewarded ad
mas.loadRewardedAd();

// Show when user taps "Watch Ad for Reward" button
function onWatchAdButtonClicked():void {
    if (mas.isRewardedAdLoaded()) {
        mas.showRewardedAd();
        // Or with placement: mas.showRewardedAd("double_coins");
    } else {
        trace("Rewarded ad not ready yet");
    }
}

// Grant the reward when the user finishes watching
function onRewardEarned(e:Yodo1MasEvent):void {
    trace("User earned reward! Grant coins/lives/etc.");
    // Add your reward logic here
}

// Reload after the ad closes
function onRewardedClosed(e:Yodo1MasEvent):void {
    mas.loadRewardedAd(); // Pre-load the next one
}
```

### App Open Ads

```actionscript
// Listen for events
mas.addEventListener(Yodo1MasEvent.APP_OPEN_AD_LOADED, onAppOpenLoaded);
mas.addEventListener(Yodo1MasEvent.APP_OPEN_AD_FAILED_TO_LOAD, onAppOpenFailed);
mas.addEventListener(Yodo1MasEvent.APP_OPEN_AD_OPENED, onAppOpenOpened);
mas.addEventListener(Yodo1MasEvent.APP_OPEN_AD_FAILED_TO_OPEN, onAppOpenFailedToOpen);
mas.addEventListener(Yodo1MasEvent.APP_OPEN_AD_CLOSED, onAppOpenClosed);

// Load an app open ad
mas.loadAppOpenAd();

// Show when returning from background
function onAppOpenLoaded(e:Yodo1MasEvent):void {
    if (mas.isAppOpenAdLoaded()) {
        mas.showAppOpenAd();
    }
}
```

### Ad Revenue Tracking

```actionscript
mas.addEventListener(Yodo1MasEvent.AD_REVENUE, function(e:Yodo1MasEvent):void {
    trace("Ad type: " + e.adType);            // "banner", "interstitial", "rewarded", "appopen"
    trace("Revenue: $" + e.revenue);           // Revenue amount
    trace("Currency: " + e.currency);          // Currency code (e.g., "USD")
    trace("Precision: " + e.revenuePrecision); // "exact", "estimated", "publisher_defined"

    // Send to your analytics (e.g., Firebase, Adjust, etc.)
});
```

---

## Complete Event Reference

| Event Constant | Description |
|----------------|-------------|
| `Yodo1MasEvent.SDK_INIT_SUCCESS` | SDK initialized successfully |
| `Yodo1MasEvent.SDK_INIT_FAILED` | SDK initialization failed (check `e.errorMessage`) |
| | |
| `Yodo1MasEvent.BANNER_AD_LOADED` | Banner ad loaded and ready to show |
| `Yodo1MasEvent.BANNER_AD_FAILED_TO_LOAD` | Banner ad failed to load |
| `Yodo1MasEvent.BANNER_AD_OPENED` | Banner ad impression registered |
| `Yodo1MasEvent.BANNER_AD_FAILED_TO_OPEN` | Banner ad failed to open |
| `Yodo1MasEvent.BANNER_AD_CLOSED` | Banner ad closed |
| | |
| `Yodo1MasEvent.INTERSTITIAL_AD_LOADED` | Interstitial ad loaded and ready to show |
| `Yodo1MasEvent.INTERSTITIAL_AD_FAILED_TO_LOAD` | Interstitial ad failed to load |
| `Yodo1MasEvent.INTERSTITIAL_AD_OPENED` | Interstitial ad displayed (impression) |
| `Yodo1MasEvent.INTERSTITIAL_AD_FAILED_TO_OPEN` | Interstitial ad failed to open |
| `Yodo1MasEvent.INTERSTITIAL_AD_CLOSED` | Interstitial ad closed by user |
| | |
| `Yodo1MasEvent.REWARDED_AD_LOADED` | Rewarded ad loaded and ready to show |
| `Yodo1MasEvent.REWARDED_AD_FAILED_TO_LOAD` | Rewarded ad failed to load |
| `Yodo1MasEvent.REWARDED_AD_OPENED` | Rewarded ad displayed |
| `Yodo1MasEvent.REWARDED_AD_FAILED_TO_OPEN` | Rewarded ad failed to open |
| `Yodo1MasEvent.REWARDED_AD_CLOSED` | Rewarded ad closed by user |
| `Yodo1MasEvent.REWARDED_AD_EARNED` | **User earned reward** |
| | |
| `Yodo1MasEvent.APP_OPEN_AD_LOADED` | App open ad loaded and ready to show |
| `Yodo1MasEvent.APP_OPEN_AD_FAILED_TO_LOAD` | App open ad failed to load |
| `Yodo1MasEvent.APP_OPEN_AD_OPENED` | App open ad displayed |
| `Yodo1MasEvent.APP_OPEN_AD_FAILED_TO_OPEN` | App open ad failed to open |
| `Yodo1MasEvent.APP_OPEN_AD_CLOSED` | App open ad closed |
| | |
| `Yodo1MasEvent.AD_REVENUE` | Revenue event with `e.adType`, `e.revenue`, `e.currency` |

### Error Event Properties

All failure events include:
- `e.errorCode` - numeric error code from the SDK
- `e.errorMessage` - human-readable error description

---

## Complete Minimal Example

```actionscript
package {
    import flash.display.Sprite;
    import com.AdobeAir.Yodo1Mas.Yodo1Mas;
    import com.AdobeAir.Yodo1Mas.Yodo1MasEvent;
    import com.AdobeAir.Yodo1Mas.Yodo1MasBannerPosition;

    public class MyGame extends Sprite {
        private var mas:Yodo1Mas;

        public function MyGame() {
            mas = Yodo1Mas.getInstance();

            // Privacy (set before init)
            mas.setCOPPA(false);
            mas.setGDPR(true);
            mas.setCCPA(false);

            // Init events
            mas.addEventListener(Yodo1MasEvent.SDK_INIT_SUCCESS, onInitSuccess);
            mas.addEventListener(Yodo1MasEvent.SDK_INIT_FAILED, onInitFailed);

            // Ad events
            mas.addEventListener(Yodo1MasEvent.BANNER_AD_LOADED, onBannerLoaded);
            mas.addEventListener(Yodo1MasEvent.INTERSTITIAL_AD_LOADED, onInterstitialLoaded);
            mas.addEventListener(Yodo1MasEvent.INTERSTITIAL_AD_CLOSED, onInterstitialClosed);
            mas.addEventListener(Yodo1MasEvent.REWARDED_AD_LOADED, onRewardedLoaded);
            mas.addEventListener(Yodo1MasEvent.REWARDED_AD_EARNED, onRewardEarned);
            mas.addEventListener(Yodo1MasEvent.REWARDED_AD_CLOSED, onRewardedClosed);

            // Initialize
            mas.initSdk("YourAppKey");
        }

        private function onInitSuccess(e:Yodo1MasEvent):void {
            trace("SDK ready! Loading ads...");
            mas.loadBannerAd();
            mas.loadInterstitialAd();
            mas.loadRewardedAd();
        }

        private function onInitFailed(e:Yodo1MasEvent):void {
            trace("SDK init failed: " + e.errorMessage);
        }

        private function onBannerLoaded(e:Yodo1MasEvent):void {
            mas.showBannerAd(null, Yodo1MasBannerPosition.BOTTOM_CENTER);
        }

        private function onInterstitialLoaded(e:Yodo1MasEvent):void {
            trace("Interstitial ready");
        }

        private function onInterstitialClosed(e:Yodo1MasEvent):void {
            mas.loadInterstitialAd(); // Reload
        }

        private function onRewardedLoaded(e:Yodo1MasEvent):void {
            trace("Rewarded ad ready");
        }

        private function onRewardEarned(e:Yodo1MasEvent):void {
            trace("Grant reward to player!");
        }

        private function onRewardedClosed(e:Yodo1MasEvent):void {
            mas.loadRewardedAd(); // Reload
        }

        // Call these from your game logic:
        public function showInterstitial():void {
            if (mas.isInterstitialAdLoaded()) mas.showInterstitialAd();
        }

        public function showRewarded():void {
            if (mas.isRewardedAdLoaded()) mas.showRewardedAd();
        }
    }
}
```

---

## API Method Reference

| Method | Description |
|--------|-------------|
| `Yodo1Mas.getInstance()` | Get the singleton instance |
| `isSupported:Boolean` | Whether the ANE is supported on this platform |
| | |
| **SDK Initialization** | |
| `initSdk(appKey:String)` | Initialize the MAS SDK with your app key |
| `setCOPPA(enabled:Boolean)` | Set COPPA age restriction (call before `initSdk`) |
| `setGDPR(consent:Boolean)` | Set GDPR user consent (call before `initSdk`) |
| `setCCPA(doNotSell:Boolean)` | Set CCPA do-not-sell flag (call before `initSdk`) |
| | |
| **Banner Ads** | |
| `loadBannerAd(placement:String = null)` | Load a banner ad |
| `showBannerAd(placement:String, position:int)` | Show banner at specified position |
| `hideBannerAd()` | Hide the banner (can show again) |
| `destroyBannerAd()` | Destroy the banner (must reload to show) |
| `isBannerAdLoaded():Boolean` | Check if a banner is loaded |
| | |
| **Interstitial Ads** | |
| `loadInterstitialAd()` | Load an interstitial ad |
| `showInterstitialAd(placement:String = null)` | Show the interstitial |
| `isInterstitialAdLoaded():Boolean` | Check if an interstitial is loaded |
| | |
| **Rewarded Ads** | |
| `loadRewardedAd()` | Load a rewarded video ad |
| `showRewardedAd(placement:String = null)` | Show the rewarded ad |
| `isRewardedAdLoaded():Boolean` | Check if a rewarded ad is loaded |
| | |
| **App Open Ads** | |
| `loadAppOpenAd()` | Load an app open ad |
| `showAppOpenAd(placement:String = null)` | Show the app open ad |
| `isAppOpenAdLoaded():Boolean` | Check if an app open ad is loaded |

---

## Building the ANE from Source

> **Most users don't need this section.** If you're integrating the ANE into your game, use the pre-built release package and follow the steps above. This section is for contributors who want to modify the native code and rebuild.

### Build Prerequisites

- **AIR SDK** 51.x+ installed
- **Android SDK** with build-tools 34+ (for Android)
- **Java JDK 17** (required by Gradle 8.13, for Android)
- **macOS** with Xcode 16+ (tested with Xcode 26.6) and CocoaPods (`gem install cocoapods`) (for iOS)
- A **stock** AIR SDK is enough: the ANE no longer depends on files copied into the AIR SDK by hand
- **Apache Ant**: `brew install ant`

### Build Steps

```bash
cd native_src

# 1. Update build.properties with your AIR SDK path
#    AIR_SDK_PATH = /path/to/your/AIRSDK

# 2. Copy FlashRuntimeExtensions.jar from AIR SDK
cp $AIR_SDK_PATH/lib/android/FlashRuntimeExtensions.jar \
   Yodo1MasAndroidProject/yodo1mas_lib/libs/

# 3. Build everything (Android JAR + collect 285 dependencies + SWC + ANE)
chmod +x build.sh
./build.sh

# Output: dest/yodo1mas.ane  +  ios_resources/ and ios_resources.zip
```

The build script will:
1. Compile the Android native library via Gradle
2. Collect all 285 runtime dependencies (JARs + AARs) with collision-safe filenames
3. Build the iOS static library, the link-fix library and collect frameworks via CocoaPods + xcodebuild
4. Compile the ActionScript SWC library
5. Package everything into `yodo1mas.ane` (Android + iOS + default platforms)
6. Package the iOS runtime resources into `ios_resources/` / `ios_resources.zip`

#### Why the iOS side has link fixes

ADT links iOS apps against the AIR SDK's own iOS 17-era system stubs (with Xcode's `ld-classic` on macOS, with the AIR SDK's `lld` on Windows). Modern ad SDKs need a few things those stubs lack or get wrong, fixed at link time so that app developers need no post-processing:

| Problem | Fix |
|---|---|
| Swift 6 shim modules (`swift_errno`, `swift_math`, ...) not in the AIR SDK | `ios/stubs/Yodo1MasLinkFixes.c`: `__swift_FORCE_LOAD_$_*` markers |
| AIR's `libSystem` stub still exports `nw_*`, so `nw_interface_get_type` / `nw_path_get_status` bound to libSystem and crashed at launch on current iOS | `ios/stubs/Yodo1MasLinkFixes.c`: local forwarders to Network.framework |
| iOS 18 UIKit classes (`UIUpdateLink`) and Swift 6 concurrency symbols missing | `ios/stubs/*.framework`: text link stubs that bind them (weakly) to the real UIKit / `libswift_Concurrency` |
| Swift back-deploy libraries | `-lSwiftCompat` (ships with the AIR SDK) |

Never put a `$` in a `platform-ios.xml` linker option: on macOS ADT runs the linker through `/bin/sh` and the option gets mangled. After changing SDK versions, check a built IPA with `python3 tools/check_ios_binds.py <app binary>`.

### Project Structure

```
native_src/
+-- Yodo1MasAndroidProject/     # Android native library (Gradle project)
|   +-- yodo1mas_lib/
|       +-- build.gradle         # Yodo1 MAS dependency + collectDependencies task
|       +-- src/main/java/com/AdobeAir/Yodo1Mas/
|           +-- Yodo1MasExtension.java  # FREExtension entry point
|           +-- Yodo1MasContext.java     # Lazy dispatch pattern
|           +-- Yodo1MasBridge.java      # SDK bridge + event dispatch
+-- ios/                                 # iOS native library
|   +-- Podfile                          # CocoaPods dependencies (Yodo1MasFull 4.17.1)
|   +-- build_ios.sh                     # iOS build script
|   +-- Yodo1MasANE/                     # Objective-C source
|       +-- Yodo1MasANE.m                # FRE bridge
|       +-- Yodo1MasBridge.m             # SDK bridge + event dispatch
+-- as/src/com/AdobeAir/Yodo1Mas/       # ActionScript library
|   +-- Yodo1Mas.as                      # Main API (singleton)
|   +-- Yodo1MasEvent.as                 # Event class
|   +-- Yodo1MasBannerPosition.as        # Banner position constants
|   +-- Yodo1MasFunNames.as             # Function name constants
+-- config/
|   +-- extension.xml                    # ANE descriptor
|   +-- platform-android.xml             # Android platform options (285 deps)
|   +-- platform-ios.xml                 # iOS platform options (76 frameworks + linker flags)
+-- ios/stubs/                           # iOS link fixes (see "Why the iOS side has link fixes")
+-- package_ios_resources.sh             # Builds ios_resources/ + ios_resources.zip
+-- tools/check_ios_binds.py             # Maintainer check of an IPA's imports
+-- demo/                                # Demo AIR application
|   +-- src/Yodo1MasDemo.as
|   +-- Yodo1MasDemo-app.xml
+-- build.xml                            # Ant build script
+-- build.properties                     # Build paths
+-- build.sh                             # One-click build
```

### Updating the ANE

After rebuilding the ANE (e.g. after changing dependencies or platform targets), follow these steps to update it in your project and on GitHub:

```bash
cd native_src

# 1. Rebuild the ANE
./build.sh
# Output: dest/yodo1mas.ane  +  ios_resources/ and ios_resources.zip

# 2. Copy the updated ANE to your demo/test project
cp dest/yodo1mas.ane demo/anes/yodo1mas.ane

# 3. If using an android-studio Gradle project, clean and rebuild the APK
cd demo/android_project
JAVA_HOME=$(/usr/libexec/java_home -v 17) ./gradlew clean assembleDebug

# 4. (Optional) Install on device to verify
adb install -r app/build/outputs/apk/debug/app-debug.apk

# 5. Commit and push to GitHub
cd ../../../
git add -A
git commit -m "Update ANE: <describe your changes>"
git push origin main
```

> **Note:** The ANE binary (`dest/yodo1mas.ane`) and demo APKs are gitignored.
> Only source files, build configs, and dependency lists are tracked in git.
> To distribute the ANE, attach it as a GitHub Release asset or host it separately.

### Creating a GitHub Release with the ANE

1. Tag the release:
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```
2. Go to your GitHub repository → **Releases** → **Create a new release**
3. Select the tag you just pushed
4. Attach `native_src/dest/yodo1mas.ane` **and** `native_src/ios_resources.zip` as release assets
5. Publish the release

Users can then download the ANE directly from the Releases page.

---

## Troubleshooting

### "Please check your AppLovinSdkKey" crash on startup
The AppLovin SDK key is hardcoded in the ANE, so this should not happen. If it does, ensure you are using the latest build of `yodo1mas.ane`.

### D8 multidex error when packaging APK
Use `adt -package -target android-studio` instead of `-target apk`. See Step 4 above.

### "ad adapters is null" for all ad types
This means adapter classes are missing from the APK. Rebuild the ANE using `./build.sh` to ensure all 285 dependencies are collected with unique filenames (the `collectDependencies` Gradle task handles filename collisions automatically).

### Error #3500: "extension context does not have a method"
The ANE was not properly packaged or the SDK dependencies are missing. Rebuild with `./build.sh`.

### ClassNotFoundException for AIRAppEntry after changing package name
If you remove the `air.` prefix from your package name, change the activity declaration in `AndroidManifest.xml` from `.AIRAppEntry` to the fully qualified `air.com.yourcompany.yourgame.AIRAppEntry`.

---

## SDK Details

- **Yodo1 MAS SDK**: `com.yodo1.mas:full:4.17.1` (Android), `Yodo1MasFull 4.17.1` (iOS via CocoaPods)
- **Minimum Android SDK**: 24 (Android 7.0)
- **Target Android SDK**: 34 (Android 14)
- **Minimum iOS**: 13.0 (deployment target), recommended 14.0+
- **Total Android dependencies**: 285 (48 JARs + 237 AARs)
- **Total iOS dependencies**: 76 static frameworks + 4 dynamic frameworks
- **ANE size**: ~330 MB (Android ARM + ARM64, iOS arm64, all ad network adapters)

## Links

- [Yodo1 MAS Dashboard](https://mas.yodo1.com/)
- [Yodo1 MAS Android Docs](https://developers.yodo1.com/docs/sdk/guides/android/integration)
- [Yodo1 MAS iOS Docs](https://developers.yodo1.com/docs/sdk/guides/ios/integration)
- [AIR SDK Downloads](https://airsdk.harman.com/download)
- [iOS Integration Details](native_src/ios/README.md)

## License

Apache 2.0
