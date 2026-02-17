package com.AdobeAir.Yodo1Mas
{
    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;
    import flash.system.Capabilities;

    /**
     * Yodo1Mas - Main ActionScript API for the Yodo1 MAS Adobe AIR Native Extension.
     * 
     * Usage:
     *   // 1. Set privacy before init
     *   Yodo1Mas.getInstance().setCOPPA(false);
     *   Yodo1Mas.getInstance().setGDPR(true);
     *   Yodo1Mas.getInstance().setCCPA(false);
     * 
     *   // 2. Listen for init events
     *   Yodo1Mas.getInstance().addEventListener(Yodo1MasEvent.SDK_INIT_SUCCESS, onInitSuccess);
     *   Yodo1Mas.getInstance().addEventListener(Yodo1MasEvent.SDK_INIT_FAILED, onInitFailed);
     * 
     *   // 3. Initialize SDK
     *   Yodo1Mas.getInstance().initSdk("YourAppKey");
     * 
     *   // 4. After init success, load and show ads
     *   Yodo1Mas.getInstance().loadInterstitialAd();
     *   Yodo1Mas.getInstance().loadRewardedAd();
     *   Yodo1Mas.getInstance().loadBannerAd();
     */

    // SDK Init Events
    [Event(name="onSdkInitSuccess", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onSdkInitFailed", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]

    // Banner Ad Events
    [Event(name="onBannerAdLoaded", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onBannerAdFailedToLoad", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onBannerAdOpened", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onBannerAdFailedToOpen", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onBannerAdClosed", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]

    // Interstitial Ad Events
    [Event(name="onInterstitialAdLoaded", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onInterstitialAdFailedToLoad", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onInterstitialAdOpened", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onInterstitialAdFailedToOpen", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onInterstitialAdClosed", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]

    // Rewarded Ad Events
    [Event(name="onRewardedAdLoaded", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onRewardedAdFailedToLoad", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onRewardedAdOpened", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onRewardedAdFailedToOpen", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onRewardedAdClosed", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onRewardedAdEarned", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]

    // App Open Ad Events
    [Event(name="onAppOpenAdLoaded", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onAppOpenAdFailedToLoad", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onAppOpenAdOpened", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onAppOpenAdFailedToOpen", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]
    [Event(name="onAppOpenAdClosed", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]

    // Revenue Event
    [Event(name="onAdRevenue", type="com.AdobeAir.Yodo1Mas.Yodo1MasEvent")]

    public class Yodo1Mas extends EventDispatcher
    {
        public static const VERSION:String = "Yodo1MAS AIR ANE v1.0.0";
        public static const EXTENSION_ID:String = "com.AdobeAir.Yodo1Mas";

        private static var _instance:Yodo1Mas;
        private var extensionContext:ExtensionContext = null;
        private var _enableTrace:Boolean = true;

        // ============ Singleton ============

        public static function getInstance():Yodo1Mas
        {
            if (_instance == null)
            {
                _instance = new Yodo1Mas();
                trace(VERSION);
            }
            return _instance;
        }

        public function Yodo1Mas()
        {
            extensionContext = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
            if (extensionContext != null)
            {
                extensionContext.addEventListener(StatusEvent.STATUS, onStatusHandler);
            }
            else
            {
                trace("Yodo1Mas: Failed to create extension context. Extension may not be supported on this platform.");
            }
        }

        /** Whether this device supports the extension (Android or iOS only) */
        public function get isSupported():Boolean
        {
            var ok:Boolean = Capabilities.manufacturer.indexOf("iOS") > -1 ||
                             Capabilities.manufacturer.indexOf("Android") > -1;
            return ok && extensionContext != null;
        }

        /** Enable or disable trace logging */
        public function set enableTrace(value:Boolean):void
        {
            _enableTrace = value;
        }

        /** Dispose the extension completely. Cannot be used after calling this. */
        public function dispose():void
        {
            if (extensionContext != null)
            {
                extensionContext.removeEventListener(StatusEvent.STATUS, onStatusHandler);
                extensionContext.dispose();
                extensionContext = null;
            }
            _instance = null;
        }

        // ============ SDK Initialization ============

        /**
         * Initialize the Yodo1 MAS SDK.
         * 
         * @param appKey Your Yodo1 MAS app key from the dashboard.
         *               Find it at: https://mas.yodo1.com/dash/games
         */
        public function initSdk(appKey:String):void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.INIT_SDK, appKey);
        }

        // ============ Privacy / Legal Configuration ============

        /**
         * Set COPPA (Children's Online Privacy Protection Act) compliance.
         * Must be called BEFORE initSdk().
         * 
         * @param enabled true for users under 13, false for users 13+
         */
        public function setCOPPA(enabled:Boolean):void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.SET_COPPA, enabled);
        }

        /**
         * Set GDPR (General Data Protection Regulation) consent.
         * Must be called BEFORE initSdk().
         * 
         * @param consent true if user consents to data collection, false otherwise
         */
        public function setGDPR(consent:Boolean):void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.SET_GDPR, consent);
        }

        /**
         * Set CCPA (California Consumer Privacy Act) opt-out.
         * Must be called BEFORE initSdk().
         * 
         * @param optOut true if user opts out of data collection, false otherwise
         */
        public function setCCPA(optOut:Boolean):void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.SET_CCPA, optOut);
        }

        // ============ Banner Ads ============

        /**
         * Load a banner ad.
         * Listen for Yodo1MasEvent.BANNER_AD_LOADED.
         * 
         * @param placement Optional placement ID for dashboard tracking
         */
        public function loadBannerAd(placement:String = null):void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.LOAD_BANNER, placement);
        }

        /**
         * Show a banner ad at the specified position.
         * 
         * @param placement Optional placement ID for dashboard tracking
         * @param position  Banner position (use Yodo1MasBannerPosition constants). Default: BOTTOM_CENTER
         */
        public function showBannerAd(placement:String = null, position:int = 1):void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.SHOW_BANNER, placement, position);
        }

        /** Hide the currently showing banner ad (can be shown again later) */
        public function hideBannerAd():void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.HIDE_BANNER);
        }

        /** Destroy the banner ad completely (must loadBannerAd again to show) */
        public function destroyBannerAd():void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.DESTROY_BANNER);
        }

        /** Check if a banner ad is currently loaded */
        public function isBannerAdLoaded():Boolean
        {
            if (!isSupported) return false;
            return extensionContext.call(Yodo1MasFunNames.IS_BANNER_LOADED);
        }

        // ============ Interstitial Ads ============

        /**
         * Load an interstitial ad.
         * Listen for Yodo1MasEvent.INTERSTITIAL_AD_LOADED.
         */
        public function loadInterstitialAd():void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.LOAD_INTERSTITIAL);
        }

        /**
         * Show an interstitial ad.
         * 
         * @param placement Optional placement ID for dashboard tracking
         */
        public function showInterstitialAd(placement:String = null):void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.SHOW_INTERSTITIAL, placement);
        }

        /** Check if an interstitial ad is loaded and ready to show */
        public function isInterstitialAdLoaded():Boolean
        {
            if (!isSupported) return false;
            return extensionContext.call(Yodo1MasFunNames.IS_INTERSTITIAL_LOADED);
        }

        // ============ Rewarded Video Ads ============

        /**
         * Load a rewarded video ad.
         * Listen for Yodo1MasEvent.REWARDED_AD_LOADED.
         */
        public function loadRewardedAd():void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.LOAD_REWARDED);
        }

        /**
         * Show a rewarded video ad.
         * Listen for Yodo1MasEvent.REWARDED_AD_EARNED to grant the reward.
         * 
         * @param placement Optional placement ID for dashboard tracking
         */
        public function showRewardedAd(placement:String = null):void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.SHOW_REWARDED, placement);
        }

        /** Check if a rewarded video ad is loaded and ready to show */
        public function isRewardedAdLoaded():Boolean
        {
            if (!isSupported) return false;
            return extensionContext.call(Yodo1MasFunNames.IS_REWARDED_LOADED);
        }

        // ============ App Open Ads ============

        /**
         * Load an app open ad.
         * Listen for Yodo1MasEvent.APP_OPEN_AD_LOADED.
         */
        public function loadAppOpenAd():void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.LOAD_APP_OPEN);
        }

        /**
         * Show an app open ad.
         * 
         * @param placement Optional placement ID for dashboard tracking
         */
        public function showAppOpenAd(placement:String = null):void
        {
            if (!isSupported) return;
            extensionContext.call(Yodo1MasFunNames.SHOW_APP_OPEN, placement);
        }

        /** Check if an app open ad is loaded and ready to show */
        public function isAppOpenAdLoaded():Boolean
        {
            if (!isSupported) return false;
            return extensionContext.call(Yodo1MasFunNames.IS_APP_OPEN_LOADED);
        }

        // ============ Event Handler ============

        private function onStatusHandler(e:StatusEvent):void
        {
            var event:Yodo1MasEvent = new Yodo1MasEvent(e.code, e.level);
            logTrace("Yodo1MAS event: " + e.code + " data: " + e.level);
            this.dispatchEvent(event);
        }

        private function logTrace(msg:String):void
        {
            if (_enableTrace) trace(msg);
        }
    }
}
