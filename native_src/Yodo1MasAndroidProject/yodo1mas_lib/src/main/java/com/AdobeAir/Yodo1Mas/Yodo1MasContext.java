package com.AdobeAir.Yodo1Mas;

import java.util.HashMap;
import java.util.Map;

import android.util.Log;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREInvalidObjectException;
import com.adobe.fre.FREObject;
import com.adobe.fre.FRETypeMismatchException;
import com.adobe.fre.FREWrongThreadException;

/**
 * Yodo1 MAS FREContext - Maps ActionScript function calls to native Java implementations.
 * 
 * This context registers all available functions that can be called from ActionScript
 * and delegates the actual SDK operations to Yodo1MasBridge.
 */
public class Yodo1MasContext extends FREContext {

    // Function name constants - must match ActionScript side
    private static final String INIT_SDK = "yodo1mas_initSdk";
    private static final String SET_COPPA = "yodo1mas_setCOPPA";
    private static final String SET_GDPR = "yodo1mas_setGDPR";
    private static final String SET_CCPA = "yodo1mas_setCCPA";

    // Banner
    private static final String LOAD_BANNER = "yodo1mas_loadBannerAd";
    private static final String SHOW_BANNER = "yodo1mas_showBannerAd";
    private static final String HIDE_BANNER = "yodo1mas_hideBannerAd";
    private static final String DESTROY_BANNER = "yodo1mas_destroyBannerAd";
    private static final String IS_BANNER_LOADED = "yodo1mas_isBannerAdLoaded";

    // Interstitial
    private static final String LOAD_INTERSTITIAL = "yodo1mas_loadInterstitialAd";
    private static final String SHOW_INTERSTITIAL = "yodo1mas_showInterstitialAd";
    private static final String IS_INTERSTITIAL_LOADED = "yodo1mas_isInterstitialAdLoaded";

    // Rewarded Video
    private static final String LOAD_REWARDED = "yodo1mas_loadRewardedAd";
    private static final String SHOW_REWARDED = "yodo1mas_showRewardedAd";
    private static final String IS_REWARDED_LOADED = "yodo1mas_isRewardedAdLoaded";

    // App Open
    private static final String LOAD_APP_OPEN = "yodo1mas_loadAppOpenAd";
    private static final String SHOW_APP_OPEN = "yodo1mas_showAppOpenAd";
    private static final String IS_APP_OPEN_LOADED = "yodo1mas_isAppOpenAdLoaded";

    private static final String TAG = "Yodo1MasANE";
    private Yodo1MasBridge bridge;
    private boolean bridgeInitAttempted = false;

    private Yodo1MasBridge getBridge() {
        if (!bridgeInitAttempted) {
            bridgeInitAttempted = true;
            try {
                bridge = new Yodo1MasBridge();
                bridge.setContext(this);
            } catch (Throwable t) {
                Log.e(TAG, "Failed to create Yodo1MasBridge. Are the Yodo1 MAS SDK dependencies included?", t);
                bridge = null;
            }
        }
        return bridge;
    }

    @Override
    public void dispose() {
        if (bridge != null) {
            try {
                bridge.dispose();
            } catch (Throwable t) {
                Log.e(TAG, "Error disposing bridge", t);
            }
            bridge = null;
        }
    }

    @Override
    public Map<String, FREFunction> getFunctions() {
        Map<String, FREFunction> functionMap = new HashMap<>();

        // Register all functions using a single anonymous class pattern
        // that only references Yodo1MasContext (not Yodo1MasBridge directly),
        // so class verification succeeds even if SDK dependencies are missing.
        String[] allFunctions = {
            INIT_SDK, SET_COPPA, SET_GDPR, SET_CCPA,
            LOAD_BANNER, SHOW_BANNER, HIDE_BANNER, DESTROY_BANNER, IS_BANNER_LOADED,
            LOAD_INTERSTITIAL, SHOW_INTERSTITIAL, IS_INTERSTITIAL_LOADED,
            LOAD_REWARDED, SHOW_REWARDED, IS_REWARDED_LOADED,
            LOAD_APP_OPEN, SHOW_APP_OPEN, IS_APP_OPEN_LOADED
        };

        for (final String funcName : allFunctions) {
            functionMap.put(funcName, new FREFunction() {
                @Override
                public FREObject call(FREContext ctx, FREObject[] args) {
                    return dispatchFunction(funcName, args);
                }
            });
        }

        return functionMap;
    }

    /**
     * Central dispatch for all functions. This method is only verified/loaded
     * when first called at runtime, so missing SDK dependencies won't prevent
     * function registration in getFunctions().
     */
    private FREObject dispatchFunction(String funcName, FREObject[] args) {
        Yodo1MasBridge b = getBridge();
        if (b == null) {
            Log.e(TAG, "Yodo1MasBridge not available for: " + funcName
                + ". Check that all Yodo1 MAS SDK dependencies are packaged in the ANE.");
            dispatchEvent("onSdkInitFailed", "Yodo1 MAS SDK dependencies not found. Cannot call: " + funcName);
            return null;
        }

        try {
            switch (funcName) {
                // SDK Init
                case INIT_SDK:
                    b.initSdk(getString(args, 0));
                    break;

                // Privacy / Legal
                case SET_COPPA:
                    b.setCOPPA(getBoolean(args, 0));
                    break;
                case SET_GDPR:
                    b.setGDPR(getBoolean(args, 0));
                    break;
                case SET_CCPA:
                    b.setCCPA(getBoolean(args, 0));
                    break;

                // Banner
                case LOAD_BANNER:
                    b.loadBannerAd(getString(args, 0));
                    break;
                case SHOW_BANNER:
                    b.showBannerAd(getString(args, 0), getInt(args, 1));
                    break;
                case HIDE_BANNER:
                    b.hideBannerAd();
                    break;
                case DESTROY_BANNER:
                    b.destroyBannerAd();
                    break;
                case IS_BANNER_LOADED:
                    return FREObject.newObject(b.isBannerAdLoaded());

                // Interstitial
                case LOAD_INTERSTITIAL:
                    b.loadInterstitialAd();
                    break;
                case SHOW_INTERSTITIAL:
                    b.showInterstitialAd(getString(args, 0));
                    break;
                case IS_INTERSTITIAL_LOADED:
                    return FREObject.newObject(b.isInterstitialAdLoaded());

                // Rewarded
                case LOAD_REWARDED:
                    b.loadRewardedAd();
                    break;
                case SHOW_REWARDED:
                    b.showRewardedAd(getString(args, 0));
                    break;
                case IS_REWARDED_LOADED:
                    return FREObject.newObject(b.isRewardedAdLoaded());

                // App Open
                case LOAD_APP_OPEN:
                    b.loadAppOpenAd();
                    break;
                case SHOW_APP_OPEN:
                    b.showAppOpenAd(getString(args, 0));
                    break;
                case IS_APP_OPEN_LOADED:
                    return FREObject.newObject(b.isAppOpenAdLoaded());

                default:
                    Log.w(TAG, "Unknown function: " + funcName);
                    break;
            }
        } catch (Throwable t) {
            Log.e(TAG, "Error calling " + funcName + ": " + t.getMessage(), t);
            dispatchEvent("onSdkInitFailed", "Error in " + funcName + ": " + t.getMessage());
        }
        return null;
    }

    // ============ Event Helper ============

    private void dispatchEvent(String code, String level) {
        try {
            dispatchStatusEventAsync(code, level != null ? level : "");
        } catch (Throwable t) {
            Log.e(TAG, "Failed to dispatch event: " + code, t);
        }
    }

    // ============ Helper methods for extracting FREObject values ============

    protected int getInt(FREObject[] args, int index) {
        if (index < 0 || index >= args.length || args[index] == null) {
            return 0;
        }
        try {
            return args[index].getAsInt();
        } catch (IllegalStateException | FRETypeMismatchException |
                 FREInvalidObjectException | FREWrongThreadException e) {
            e.printStackTrace();
        }
        return 0;
    }

    protected boolean getBoolean(FREObject[] args, int index) {
        if (index < 0 || index >= args.length || args[index] == null) {
            return false;
        }
        try {
            return args[index].getAsBool();
        } catch (IllegalStateException | FRETypeMismatchException |
                 FREInvalidObjectException | FREWrongThreadException e) {
            e.printStackTrace();
        }
        return false;
    }

    protected String getString(FREObject[] args, int index) {
        if (index < 0 || index >= args.length || args[index] == null) {
            return null;
        }
        try {
            return args[index].getAsString();
        } catch (IllegalStateException | FRETypeMismatchException |
                 FREInvalidObjectException | FREWrongThreadException e) {
            e.printStackTrace();
        }
        return null;
    }

    protected double getDouble(FREObject[] args, int index) {
        if (index < 0 || index >= args.length || args[index] == null) {
            return 0.0;
        }
        try {
            return args[index].getAsDouble();
        } catch (IllegalStateException | FRETypeMismatchException |
                 FREInvalidObjectException | FREWrongThreadException e) {
            e.printStackTrace();
        }
        return 0.0;
    }
}
