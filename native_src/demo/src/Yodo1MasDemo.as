package
{
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.events.MouseEvent;

    import com.AdobeAir.Yodo1Mas.Yodo1Mas;
    import com.AdobeAir.Yodo1Mas.Yodo1MasEvent;
    import com.AdobeAir.Yodo1Mas.Yodo1MasBannerPosition;

    /**
     * Yodo1 MAS ANE Demo Application
     * 
     * This demo shows how to integrate all Yodo1 MAS ad formats
     * in an Adobe AIR application.
     */
    public class Yodo1MasDemo extends Sprite
    {
        // Replace with your actual Yodo1 MAS App Key
        private static const APP_KEY:String = "UVkF740ewG";

        private var logField:TextField;
        private var yodo1mas:Yodo1Mas;
        private var buttonY:int = 10;

        public function Yodo1MasDemo()
        {
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;

            setupUI();
            setupYodo1Mas();
        }

        // ============ UI Setup ============

        private function setupUI():void
        {
            // Title
            var title:TextField = createLabel("Yodo1 MAS ANE Demo", 20, true);
            title.x = 10;
            title.y = buttonY;
            addChild(title);
            buttonY += 40;

            // SDK Buttons
            createButton("Init SDK", onInitSdk);
            buttonY += 10; // spacer

            // Banner Buttons
            createButton("Load Banner", onLoadBanner);
            createButton("Show Banner (Bottom)", onShowBannerBottom);
            createButton("Show Banner (Top)", onShowBannerTop);
            createButton("Hide Banner", onHideBanner);
            createButton("Destroy Banner", onDestroyBanner);
            buttonY += 10;

            // Interstitial Buttons
            createButton("Load Interstitial", onLoadInterstitial);
            createButton("Show Interstitial", onShowInterstitial);
            buttonY += 10;

            // Rewarded Buttons
            createButton("Load Rewarded", onLoadRewarded);
            createButton("Show Rewarded", onShowRewarded);
            buttonY += 10;

            // App Open Buttons
            createButton("Load App Open", onLoadAppOpen);
            createButton("Show App Open", onShowAppOpen);

            // Log output
            logField = new TextField();
            logField.x = 10;
            logField.y = buttonY + 10;
            logField.width = stage.stageWidth - 20;
            logField.height = stage.stageHeight - buttonY - 20;
            logField.multiline = true;
            logField.wordWrap = true;
            logField.border = true;
            logField.defaultTextFormat = new TextFormat("_sans", 12);
            addChild(logField);
        }

        private function createButton(label:String, handler:Function):void
        {
            var btn:Sprite = new Sprite();
            btn.graphics.beginFill(0x4CAF50);
            btn.graphics.drawRoundRect(0, 0, 250, 35, 8, 8);
            btn.graphics.endFill();

            var tf:TextField = createLabel(label, 14, false, 0xFFFFFF);
            tf.x = 10;
            tf.y = 8;
            tf.mouseEnabled = false;
            btn.addChild(tf);

            btn.x = 10;
            btn.y = buttonY;
            btn.buttonMode = true;
            btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { handler(); });
            addChild(btn);
            buttonY += 40;
        }

        private function createLabel(text:String, size:int, bold:Boolean = false, color:uint = 0x000000):TextField
        {
            var tf:TextField = new TextField();
            tf.defaultTextFormat = new TextFormat("_sans", size, color, bold);
            tf.text = text;
            tf.autoSize = "left";
            tf.selectable = false;
            return tf;
        }

        private function log(msg:String):void
        {
            trace("[Yodo1MasDemo] " + msg);
            logField.appendText(msg + "\n");
            logField.scrollV = logField.maxScrollV;
        }

        // ============ Yodo1 MAS Setup ============

        private function setupYodo1Mas():void
        {
            yodo1mas = Yodo1Mas.getInstance();

            // SDK Init events
            yodo1mas.addEventListener(Yodo1MasEvent.SDK_INIT_SUCCESS, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.SDK_INIT_FAILED, onEvent);

            // Banner events
            yodo1mas.addEventListener(Yodo1MasEvent.BANNER_AD_LOADED, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.BANNER_AD_FAILED_TO_LOAD, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.BANNER_AD_OPENED, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.BANNER_AD_CLOSED, onEvent);

            // Interstitial events
            yodo1mas.addEventListener(Yodo1MasEvent.INTERSTITIAL_AD_LOADED, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.INTERSTITIAL_AD_FAILED_TO_LOAD, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.INTERSTITIAL_AD_OPENED, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.INTERSTITIAL_AD_CLOSED, onEvent);

            // Rewarded events
            yodo1mas.addEventListener(Yodo1MasEvent.REWARDED_AD_LOADED, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.REWARDED_AD_FAILED_TO_LOAD, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.REWARDED_AD_OPENED, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.REWARDED_AD_CLOSED, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.REWARDED_AD_EARNED, onRewardEarned);

            // App Open events
            yodo1mas.addEventListener(Yodo1MasEvent.APP_OPEN_AD_LOADED, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.APP_OPEN_AD_FAILED_TO_LOAD, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.APP_OPEN_AD_OPENED, onEvent);
            yodo1mas.addEventListener(Yodo1MasEvent.APP_OPEN_AD_CLOSED, onEvent);

            // Revenue event
            yodo1mas.addEventListener(Yodo1MasEvent.AD_REVENUE, onAdRevenue);

            log("Yodo1 MAS ANE initialized. isSupported: " + yodo1mas.isSupported);
        }

        // ============ Event Handlers ============

        private function onEvent(e:Yodo1MasEvent):void
        {
            var msg:String = "Event: " + e.type;
            if (e.errorMessage) msg += " | Error: " + e.errorMessage;
            log(msg);
        }

        private function onRewardEarned(e:Yodo1MasEvent):void
        {
            log("*** REWARD EARNED! Grant the reward to the user. ***");
        }

        private function onAdRevenue(e:Yodo1MasEvent):void
        {
            log("Revenue: " + e.adType + " | $" + e.revenue + " " + e.currency + " (" + e.revenuePrecision + ")");
        }

        // ============ Button Handlers ============

        private function onInitSdk():void
        {
            log("Initializing SDK with key: " + APP_KEY);
            // Set privacy BEFORE init
            yodo1mas.setCOPPA(false);
            yodo1mas.setGDPR(true);
            yodo1mas.setCCPA(false);
            // Init
            yodo1mas.initSdk(APP_KEY);
        }

        private function onLoadBanner():void
        {
            log("Loading banner ad...");
            yodo1mas.loadBannerAd();
        }

        private function onShowBannerBottom():void
        {
            log("Showing banner at bottom...");
            yodo1mas.showBannerAd(null, Yodo1MasBannerPosition.BOTTOM_CENTER);
        }

        private function onShowBannerTop():void
        {
            log("Showing banner at top...");
            yodo1mas.showBannerAd(null, Yodo1MasBannerPosition.TOP_CENTER);
        }

        private function onHideBanner():void
        {
            log("Hiding banner...");
            yodo1mas.hideBannerAd();
        }

        private function onDestroyBanner():void
        {
            log("Destroying banner...");
            yodo1mas.destroyBannerAd();
        }

        private function onLoadInterstitial():void
        {
            log("Loading interstitial ad...");
            yodo1mas.loadInterstitialAd();
        }

        private function onShowInterstitial():void
        {
            if (yodo1mas.isInterstitialAdLoaded())
            {
                log("Showing interstitial...");
                yodo1mas.showInterstitialAd();
            }
            else
            {
                log("Interstitial not loaded yet!");
            }
        }

        private function onLoadRewarded():void
        {
            log("Loading rewarded ad...");
            yodo1mas.loadRewardedAd();
        }

        private function onShowRewarded():void
        {
            if (yodo1mas.isRewardedAdLoaded())
            {
                log("Showing rewarded ad...");
                yodo1mas.showRewardedAd();
            }
            else
            {
                log("Rewarded ad not loaded yet!");
            }
        }

        private function onLoadAppOpen():void
        {
            log("Loading app open ad...");
            yodo1mas.loadAppOpenAd();
        }

        private function onShowAppOpen():void
        {
            if (yodo1mas.isAppOpenAdLoaded())
            {
                log("Showing app open ad...");
                yodo1mas.showAppOpenAd();
            }
            else
            {
                log("App open ad not loaded yet!");
            }
        }
    }
}
