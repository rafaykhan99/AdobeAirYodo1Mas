package com.AdobeAir.Yodo1Mas
{
    /**
     * Function name constants shared between ActionScript and Java native code.
     * These must exactly match the constants in Yodo1MasContext.java.
     */
    internal class Yodo1MasFunNames
    {
        // SDK Init
        public static const INIT_SDK:String = "yodo1mas_initSdk";
        public static const SET_COPPA:String = "yodo1mas_setCOPPA";
        public static const SET_GDPR:String = "yodo1mas_setGDPR";
        public static const SET_CCPA:String = "yodo1mas_setCCPA";

        // Banner
        public static const LOAD_BANNER:String = "yodo1mas_loadBannerAd";
        public static const SHOW_BANNER:String = "yodo1mas_showBannerAd";
        public static const HIDE_BANNER:String = "yodo1mas_hideBannerAd";
        public static const DESTROY_BANNER:String = "yodo1mas_destroyBannerAd";
        public static const IS_BANNER_LOADED:String = "yodo1mas_isBannerAdLoaded";

        // Interstitial
        public static const LOAD_INTERSTITIAL:String = "yodo1mas_loadInterstitialAd";
        public static const SHOW_INTERSTITIAL:String = "yodo1mas_showInterstitialAd";
        public static const IS_INTERSTITIAL_LOADED:String = "yodo1mas_isInterstitialAdLoaded";

        // Rewarded Video
        public static const LOAD_REWARDED:String = "yodo1mas_loadRewardedAd";
        public static const SHOW_REWARDED:String = "yodo1mas_showRewardedAd";
        public static const IS_REWARDED_LOADED:String = "yodo1mas_isRewardedAdLoaded";

        // App Open
        public static const LOAD_APP_OPEN:String = "yodo1mas_loadAppOpenAd";
        public static const SHOW_APP_OPEN:String = "yodo1mas_showAppOpenAd";
        public static const IS_APP_OPEN_LOADED:String = "yodo1mas_isAppOpenAdLoaded";

    }
}
