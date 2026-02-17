package com.AdobeAir.Yodo1Mas
{
    import flash.events.Event;

    /**
     * Yodo1MasEvent - Event class for all Yodo1 MAS ad events.
     * 
     * Dispatched by the Yodo1Mas singleton when ad lifecycle events occur
     * (loaded, failed, opened, closed, rewarded, revenue, etc.)
     */
    public class Yodo1MasEvent extends Event
    {
        // SDK Init Events
        public static const SDK_INIT_SUCCESS:String = "onSdkInitSuccess";
        public static const SDK_INIT_FAILED:String = "onSdkInitFailed";

        // Banner Ad Events
        public static const BANNER_AD_LOADED:String = "onBannerAdLoaded";
        public static const BANNER_AD_FAILED_TO_LOAD:String = "onBannerAdFailedToLoad";
        public static const BANNER_AD_OPENED:String = "onBannerAdOpened";
        public static const BANNER_AD_FAILED_TO_OPEN:String = "onBannerAdFailedToOpen";
        public static const BANNER_AD_CLOSED:String = "onBannerAdClosed";

        // Interstitial Ad Events
        public static const INTERSTITIAL_AD_LOADED:String = "onInterstitialAdLoaded";
        public static const INTERSTITIAL_AD_FAILED_TO_LOAD:String = "onInterstitialAdFailedToLoad";
        public static const INTERSTITIAL_AD_OPENED:String = "onInterstitialAdOpened";
        public static const INTERSTITIAL_AD_FAILED_TO_OPEN:String = "onInterstitialAdFailedToOpen";
        public static const INTERSTITIAL_AD_CLOSED:String = "onInterstitialAdClosed";

        // Rewarded Ad Events
        public static const REWARDED_AD_LOADED:String = "onRewardedAdLoaded";
        public static const REWARDED_AD_FAILED_TO_LOAD:String = "onRewardedAdFailedToLoad";
        public static const REWARDED_AD_OPENED:String = "onRewardedAdOpened";
        public static const REWARDED_AD_FAILED_TO_OPEN:String = "onRewardedAdFailedToOpen";
        public static const REWARDED_AD_CLOSED:String = "onRewardedAdClosed";
        public static const REWARDED_AD_EARNED:String = "onRewardedAdEarned";

        // App Open Ad Events
        public static const APP_OPEN_AD_LOADED:String = "onAppOpenAdLoaded";
        public static const APP_OPEN_AD_FAILED_TO_LOAD:String = "onAppOpenAdFailedToLoad";
        public static const APP_OPEN_AD_OPENED:String = "onAppOpenAdOpened";
        public static const APP_OPEN_AD_FAILED_TO_OPEN:String = "onAppOpenAdFailedToOpen";
        public static const APP_OPEN_AD_CLOSED:String = "onAppOpenAdClosed";

        // Revenue Event (all ad types)
        public static const AD_REVENUE:String = "onAdRevenue";

        /** Additional data from the event (error code, error message, revenue info, etc.) */
        public var data:String;

        /** Error code if the event is a failure event */
        public var errorCode:String;

        /** Error message if the event is a failure event */
        public var errorMessage:String;

        /** Ad type for revenue events (banner, interstitial, rewarded, appopen) */
        public var adType:String;

        /** Revenue amount for revenue events */
        public var revenue:Number = 0;

        /** Currency for revenue events */
        public var currency:String;

        /** Revenue precision for revenue events */
        public var revenuePrecision:String;

        public function Yodo1MasEvent(type:String, data:String = "", bubbles:Boolean = false, cancelable:Boolean = false)
        {
            super(type, bubbles, cancelable);
            this.data = data;
            parseData(type, data);
        }

        private function parseData(type:String, data:String):void
        {
            if (data == null || data.length == 0) return;

            if (type == AD_REVENUE)
            {
                // Format: "adType|revenue|currency|precision"
                var revParts:Array = data.split("|");
                if (revParts.length >= 4)
                {
                    this.adType = revParts[0];
                    this.revenue = parseFloat(revParts[1]);
                    this.currency = revParts[2];
                    this.revenuePrecision = revParts[3];
                }
            }
            else if (type.indexOf("Failed") >= 0 || type.indexOf("failed") >= 0)
            {
                // Format: "errorCode|errorMessage"
                var errParts:Array = data.split("|");
                if (errParts.length >= 2)
                {
                    this.errorCode = errParts[0];
                    this.errorMessage = errParts[1];
                }
                else
                {
                    this.errorMessage = data;
                }
            }
        }

        override public function clone():Event
        {
            return new Yodo1MasEvent(type, data, bubbles, cancelable);
        }

        override public function toString():String
        {
            return "[Yodo1MasEvent type=\"" + type + "\" data=\"" + data + "\"]";
        }
    }
}
