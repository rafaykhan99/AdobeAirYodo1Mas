# ============================================================
# Yodo1 MAS SDK ProGuard Rules
# From: https://developers.yodo1.com/docs/sdk/advanced/proguard
# ============================================================

-ignorewarnings

# Yodo1 MAS
-keeppackagenames com.yodo1.**
-keep class com.yodo1.** { *; }
-keep class com.yodo1.mas.** { *; }
-keep class com.yodo1.mas.ad.** {*;}
-keep class com.yodo1.mas.ads.** {*;}
-keep class com.yodo1.mas.error.** { *; }
-keep class com.yodo1.mas.event.** { *; }
-keep public class * extends com.yodo1.mas.mediation.Yodo1MasAdapterBase
-keep public class * extends com.yodo1.mas.ad.Yodo1MasAdAdapterBase

# Google Ads
-keep class com.google.ads.** { *; }

# IronSource
-keepclassmembers class com.ironsource.sdk.controller.IronSourceWebView$JSInterface {
    public *;
}
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
-keep public class com.google.android.gms.ads.** {public *;}
-keep class com.ironsource.adapters.** {*;}
-dontwarn com.ironsource.mediationsdk.**
-dontwarn com.ironsource.adapters.**

# Moat
-dontwarn com.moat.**
-keep class com.moat.** { public protected private *; }

# JavaScript Interface
-keepattributes SourceFile,LineNumberTable
-keepattributes JavascriptInterface
-keep class android.webkit.JavascriptInterface {*;}

# Unity Ads
-keep class com.unity3d.ads.** {*;}
-keep class com.unity3d.services.** {*;}
-dontwarn com.google.ar.core.**
-dontwarn com.unity3d.services.**
-dontwarn com.ironsource.adapters.unityads.**

# AppLovin
-keepattributes Signature,InnerClasses,Exceptions,Annotation
-keep public class com.applovin.sdk.AppLovinSdk{ *; }
-keep public class com.applovin.sdk.AppLovin* {public protected *;}
-keep public class com.applovin.nativeAds.AppLovin* {public protected *;}
-keep public class com.applovin.adview.* {public protected *;}
-keep public class com.applovin.mediation.* {public protected *;}
-keep public class com.applovin.mediation.ads.* {public protected *;}
-keep public class com.applovin.impl.*.AppLovin {public protected *;}
-keep public class com.applovin.impl.**.*Impl {public protected *;}
-keepclassmembers class com.applovin.sdk.AppLovinSdkSettings {
    private java.util.Map localSettings;
}
-keep class com.applovin.mediation.adapters.** {*;}
-keep class com.applovin.mediation.adapter.**{*;}

# Chartboost
-keep class com.chartboost.** {*;}

# Facebook / Meta
-dontwarn com.facebook.ads.internal.**
-keeppackagenames com.facebook.*
-keep public class com.facebook.ads.** {public protected *;}

# Tapjoy
-keep class com.tapjoy.** { *; }

# Moat (duplicate - kept for safety)
-keep class com.moat.** { *; }

# JavaScript & Annotations
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Google Play Services
-keep class * extends java.util.ListResourceBundle {
    protected Object[][] getContents();
}
-keep public class com.google.android.gms.common.internal.safeparcel.SafeParcelable {
    public static final *** NULL;
}
-keepnames @com.google.android.gms.common.annotation.KeepName class *
-keepclassmembernames class * {
    @com.google.android.gms.common.annotation.KeepName *;
}
-keepnames class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
-keep class com.google.android.gms.ads.identifier.** { *; }

# Vungle
-dontwarn com.tapjoy.**
-dontwarn com.vungle.ads.**
-keepclassmembers class com.vungle.ads.** { *; }

# Moat (again)
-keep class com.moat.** { *; }
-dontwarn com.moat.**

# OkHttp + Okio
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn okio.**
-dontwarn retrofit2.Platform$Java8
-keepattributes Signature
-keepattributes *Annotation*

# Gson
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-dontwarn com.google.android.gms.ads.identifier.**

# MyTarget & Yandex
-keepattributes SourceFile,LineNumberTable
-keep class com.my.target.** {*;}
-keep class com.yandex.mobile.ads.** {*;}
-dontwarn com.yandex.mobile.ads.**

# ByteDance / Pangle
-keepattributes *Annotation*
-keep class com.bytedance.sdk.** { *; }

# Tencent Bugly
-dontwarn com.tencent.bugly.**
-keep public class com.tencent.bugly.**{*;}

# SensorsData
-dontwarn com.sensorsdata.analytics.android.**
-keep class com.sensorsdata.analytics.android.** {*;}
-keep class com.yodo1.sensor.** {*;}

# Resources
-keep class **.R$* {<fields>;}
-keep public class * extends android.content.ContentProvider
-keepnames class * extends android.view.View

# Fragments
-keep class * extends android.app.Fragment {
    public void setUserVisibleHint(boolean);
    public void onHiddenChanged(boolean);
    public void onResume();
    public void onPause();
}
-keep class android.support.v4.app.Fragment {
    public void setUserVisibleHint(boolean);
    public void onHiddenChanged(boolean);
    public void onResume();
    public void onPause();
}
-keep class * extends android.support.v4.app.Fragment {
    public void setUserVisibleHint(boolean);
    public void onHiddenChanged(boolean);
    public void onResume();
    public void onPause();
}

# JSON
-dontwarn org.json.**
-keep class org.json.**{*;}

# InMobi
-keepattributes SourceFile,LineNumberTable
-keep class com.inmobi.** {*;}
-keep public class com.google.android.gms.**
-dontwarn com.google.android.gms.**
-dontwarn com.squareup.picasso.**
-keep class com.google.android.gms.ads.identifier.AdvertisingIdClient{ public *; }
-keep class com.google.android.gms.ads.identifier.AdvertisingIdClient$Info{ public *; }

# Picasso
-keep class com.squareup.picasso.** {*;}

# OkHttp + Okio (extended)
-dontwarn javax.annotation.**
-adaptresourcefilenames okhttp3/internal/publicsuffix/PublicSuffixDatabase.gz
-dontwarn org.codehaus.mojo.animal_sniffer.*
-dontwarn okhttp3.internal.platform.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn org.codehaus.mojo.animal_sniffer.*

# Protobuf
-dontwarn com.google.protobuf.**
-keepclassmembers class com.google.protobuf.** { *; }
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }

# IAB
-keep class com.iab.** {*;}
-dontwarn com.iab.**

# Umeng
-keep class com.umeng.** {*;}
-keep class com.uc.** {*;}

# Enums
-keepclassmembers class * {
    public <init> (org.json.JSONObject);
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Chinese OEM
-keep class com.zui.** {*;}
-keep class com.miui.** {*;}
-keep class com.heytap.** {*;}
-keep class a.** {*;}
-keep class com.vivo.** {*;}

# UC CrashSDK
-keep class com.uc.crashsdk.** { *; }
-keep interface com.uc.crashsdk.** { *; }

# ThinkingData
-keep class cn.thinkinganalyticsclone.android.** { *; }
-dontwarn cn.thinkinganalyticsclone.android.thirdparty.**

# Ktor
-keep class io.ktor.**

# TradPlus
-keep public class com.tradplus.** { *; }
-keep class com.tradplus.ads.** { *; }

# YsoNetwork
-keep class com.ysocorp.ysonetwork.* { *; }

# Maticoo
-dontskipnonpubliclibraryclasses
-keep class com.maticoo.sdk.**{*;}
-keep class com.maticooad.sdk.**{*;}
-keepclassmembers class **.R$* {
    public static <fields>;
}
-keepattributes *Annotation*,InnerClasses

# Parcelable
-keepnames class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Google AppSet & Tasks
-keep class com.google.android.gms.appset.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# IronSource (extended)
-keepclassmembers class com.ironsource.** { public *; }
-keep public class com.ironsource.**

# OMID
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Facebook integration
-keepclassmembers class com.facebook.ads.internal.AdSdkVersion {
    static *;
}
-keepclassmembers class com.facebook.ads.internal.settings.AdSdkVersion {
    static *;
}
-keepclassmembers class com.facebook.ads.BuildConfig {
    static *;
}
-keep public interface com.facebook.ads** {*; }

# Fyber (Inneractive)
-keep public interface com.fyber.inneractive.sdk.external** {*; }
-keep public interface com.fyber.inneractive.sdk.activities** {*; }
-keep public interface com.fyber.inneractive.sdk.ui** {*; }

# InMobi interfaces
-keep public interface com.inmobi.ads.listeners** {*; }
-keep public interface com.inmobi.ads.InMobiInterstitial** {*; }
-keep public interface com.inmobi.ads.InMobiBanner** {*; }

# IronSource interfaces
-keep public interface com.ironsource.mediationsdk.sdk** {*; }
-keep public interface com.ironsource.mediationsdk.impressionData.ImpressionDataListener {*; }

# Mintegral interfaces
-keep public interface com.mbridge.msdk.out** {*; }
-keep public interface com.mbridge.msdk.videocommon.listener** {*; }
-keep public interface com.mbridge.msdk.interstitialvideo.out** {*; }
-keep public interface com.mintegral.msdk.out** {*; }
-keep public interface com.mintegral.msdk.videocommon.listener** {*; }
-keep public interface com.mintegral.msdk.interstitialvideo.out** {*; }

# Vungle interfaces
-keep public interface com.vungle.warren.PlayAdCallback {*; }
-keep public interface com.vungle.warren.ui.contract** {*; }
-keep public interface com.vungle.warren.ui.view** {*; }

# AndroidX
-keep class androidx.localbroadcastmanager.content.LocalBroadcastManager { *;}
-keep class androidx.recyclerview.widget.RecyclerView { *;}
-keep class androidx.recyclerview.widget.RecyclerView$OnScrollListener { *;}

# Android Activities
-keep class * extends android.app.Activity

# ============================================================
# Additional rules for ANE library module
# ============================================================

# Keep our ANE bridge class
-keep class com.yodo1.mas.air.** { *; }

# Don't warn about missing classes from optional dependencies
-dontwarn com.google.android.play.**
-dontwarn com.google.errorprone.**
-dontwarn javax.annotation.**
-dontwarn kotlin.**
-dontwarn kotlinx.**
