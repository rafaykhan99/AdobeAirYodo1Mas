# Yodo1 MAS Adobe AIR Native Extension (ANE)

Yodo1 MAS (Mediation Ad SDK) plugin for Adobe AIR, supporting Android.

This ANE wraps the [Yodo1 MAS SDK 4.17.1](https://developers.yodo1.com/) for use in Adobe AIR / ActionScript 3 projects, providing access to multiple ad networks (AdMob, AppLovin, Unity Ads, Vungle, Mintegral, InMobi, Fyber, Bigo, and more) through a single integration.

## Supported Ad Formats

| Format | Android |
|--------|---------|
| Banner | ✅ |
| Interstitial | ✅ |
| Rewarded Video | ✅ |
| App Open | ✅ |

---

## Integration Guide

### Prerequisites

- **AIR SDK** 51.x+ ([Download](https://airsdk.harman.com/download))
- **Android SDK** with build-tools 34+
- **Java JDK 17** (required by Gradle 8.x)
- A [Yodo1 MAS Dashboard](https://mas.yodo1.com/) account with your app registered
- Your **Yodo1 App Key** and **AdMob App ID** (found in the MAS Dashboard)

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
            <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="34"/>

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

### Step 3: Build with `android-studio` Target

Due to the large number of SDK dependencies (280+), you **must** use ADT's `android-studio` target instead of direct APK packaging:

```bash
# 1. Generate a Gradle project (instead of building an APK directly)
adt -package \
    -target android-studio \
    -storetype pkcs12 -keystore your-cert.p12 -storepass YOUR_PASSWORD \
    android_project \
    YourApp-app.xml \
    YourApp.swf \
    -extdir anes

# 2. Copy a working Gradle wrapper into the generated project
#    (The AIR SDK's bundled wrapper may not work with AGP 8.x)
cp /path/to/working/gradlew android_project/
cp /path/to/working/gradle/wrapper/gradle-wrapper.jar android_project/gradle/wrapper/

# 3. If you need to remove the "air." prefix from your package name:
#    Edit android_project/app/build.gradle:
#      namespace "com.yourcompany.yourgame"      (remove "air." prefix)
#      applicationId "com.yourcompany.yourgame"   (remove "air." prefix)
#    Edit android_project/app/src/main/AndroidManifest.xml:
#      Remove the package="..." attribute entirely
#      Change android:name=".AIRAppEntry" to:
#        android:name="air.com.yourcompany.yourgame.AIRAppEntry"

# 4. (Optional) Reduce APK size by removing emulator-only ABIs:
#    By default the APK includes x86 and x86_64 native libraries which are only
#    needed for Android emulators. Removing them saves ~45 MB.
#    Edit android_project/app/build.gradle and add an ndk block inside defaultConfig:
#
#      defaultConfig {
#          ...
#          ndk {
#              abiFilters 'arm64-v8a', 'armeabi-v7a'
#          }
#      }
#
#    To also drop older 32-bit ARM support (armeabi-v7a) for an additional ~16 MB
#    savings, use only:
#          ndk { abiFilters 'arm64-v8a' }
#    Note: This does not affect the ANE itself, only what gets packaged in the APK.

# 5. Build the APK with Gradle
cd android_project
JAVA_HOME=$(/usr/libexec/java_home -v 17) ./gradlew assembleDebug

# 6. Install
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

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

### Prerequisites

- **AIR SDK** 51.x+ installed
- **Android SDK** with build-tools 34+
- **Java JDK 17** (required by Gradle 8.13)
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

# Output: dest/yodo1mas.ane
```

The build script will:
1. Compile the Android native library via Gradle
2. Collect all 285 runtime dependencies (JARs + AARs) with collision-safe filenames
3. Compile the ActionScript SWC library
4. Package everything into `yodo1mas.ane`

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
+-- as/src/com/AdobeAir/Yodo1Mas/       # ActionScript library
|   +-- Yodo1Mas.as                      # Main API (singleton)
|   +-- Yodo1MasEvent.as                 # Event class
|   +-- Yodo1MasBannerPosition.as        # Banner position constants
|   +-- Yodo1MasFunNames.as             # Function name constants
+-- config/
|   +-- extension.xml                    # ANE descriptor
|   +-- platform-android.xml             # Android platform options (285 deps)
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
# Output: dest/yodo1mas.ane

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
4. Attach `native_src/dest/yodo1mas.ane` as a release asset
5. Publish the release

Users can then download the ANE directly from the Releases page.

---

## Troubleshooting

### "Please check your AppLovinSdkKey" crash on startup
The AppLovin SDK key is hardcoded in the ANE, so this should not happen. If it does, ensure you are using the latest build of `yodo1mas.ane`.

### D8 multidex error when packaging APK
Use `adt -package -target android-studio` instead of `-target apk`. See Step 3 above.

### "ad adapters is null" for all ad types
This means adapter classes are missing from the APK. Rebuild the ANE using `./build.sh` to ensure all 285 dependencies are collected with unique filenames (the `collectDependencies` Gradle task handles filename collisions automatically).

### Error #3500: "extension context does not have a method"
The ANE was not properly packaged or the SDK dependencies are missing. Rebuild with `./build.sh`.

### ClassNotFoundException for AIRAppEntry after changing package name
If you remove the `air.` prefix from your package name, change the activity declaration in `AndroidManifest.xml` from `.AIRAppEntry` to the fully qualified `air.com.yourcompany.yourgame.AIRAppEntry`.

---

## SDK Details

- **Yodo1 MAS SDK**: `com.yodo1.mas:full:4.17.1`
- **Minimum Android SDK**: 24 (Android 7.0)
- **Target Android SDK**: 34 (Android 14)
- **Total dependencies**: 285 (48 JARs + 237 AARs)
- **ANE size**: ~150 MB (ARM + ARM64, all ad network adapters; x86 removed to reduce size)

## Links

- [Yodo1 MAS Dashboard](https://mas.yodo1.com/)
- [Yodo1 MAS Android Docs](https://developers.yodo1.com/docs/sdk/guides/android/integration)
- [AIR SDK Downloads](https://airsdk.harman.com/download)

## License

Apache 2.0
