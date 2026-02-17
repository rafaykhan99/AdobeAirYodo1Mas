package com.AdobeAir.Yodo1Mas;

import android.app.Activity;
import android.util.Log;

import androidx.annotation.NonNull;

import com.adobe.fre.FREContext;

import com.yodo1.mas.Yodo1Mas;
import com.yodo1.mas.Yodo1MasSdkConfiguration;
import com.yodo1.mas.ad.Yodo1MasAdValue;
import com.yodo1.mas.appopenad.Yodo1MasAppOpenAd;
import com.yodo1.mas.appopenad.Yodo1MasAppOpenAdListener;
import com.yodo1.mas.appopenad.Yodo1MasAppOpenAdRevenueListener;
import com.yodo1.mas.banner.Yodo1MasBannerAdListener;
import com.yodo1.mas.banner.Yodo1MasBannerAdRevenueListener;
import com.yodo1.mas.banner.Yodo1MasBannerAdSize;
import com.yodo1.mas.banner.Yodo1MasBannerAdView;
import com.yodo1.mas.error.Yodo1MasError;
import com.yodo1.mas.helper.model.Yodo1MasAdBuildConfig;
import com.yodo1.mas.interstitial.Yodo1MasInterstitialAd;
import com.yodo1.mas.interstitial.Yodo1MasInterstitialAdListener;
import com.yodo1.mas.interstitial.Yodo1MasInterstitialAdRevenueListener;
import com.yodo1.mas.reward.Yodo1MasRewardAd;
import com.yodo1.mas.reward.Yodo1MasRewardAdListener;
import com.yodo1.mas.reward.Yodo1MasRewardAdRevenueListener;

import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.FrameLayout;

/**
 * Yodo1MasBridge - The actual bridge between FREContext and the Yodo1 MAS SDK.
 *
 * This class handles all native Yodo1 MAS SDK operations and dispatches
 * status events back to ActionScript via FREContext.dispatchStatusEventAsync().
 */
public class Yodo1MasBridge {

    private static final String TAG = "Yodo1MasANE";

    private FREContext freContext;
    private Activity activity;

    // Ad instances
    private Yodo1MasBannerAdView bannerAdView;

    // ============ Lifecycle ============

    public void setContext(FREContext context) {
        this.freContext = context;
        this.activity = context.getActivity();
    }

    public void dispose() {
        destroyBannerAd();
        freContext = null;
        activity = null;
    }

    // ============ Events dispatching to ActionScript ============

    private void dispatchEvent(String code, String level) {
        if (freContext != null) {
            freContext.dispatchStatusEventAsync(code, level != null ? level : "");
        }
    }

    private void dispatchAdRevenueEvent(String adType, Yodo1MasAdValue adValue) {
        if (adValue != null) {
            String data = adValue.getRevenue() + "|" + adValue.getCurrency() + "|" + adValue.getRevenuePrecision();
            dispatchEvent("onAdRevenue", adType + "|" + data);
        }
    }

    // ============ SDK Init ============

    public void initSdk(final String appKey) {
        if (activity == null) {
            Log.e(TAG, "Activity is null, cannot init SDK");
            dispatchEvent("onSdkInitFailed", "Activity is null");
            return;
        }

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                // Set auto-delay for all ad types before init
                Yodo1MasAppOpenAd.getInstance().autoDelayIfLoadFail = true;
                Yodo1MasRewardAd.getInstance().autoDelayIfLoadFail = true;
                Yodo1MasInterstitialAd.getInstance().autoDelayIfLoadFail = true;

                Yodo1Mas.getInstance().initMas(activity, appKey, new Yodo1Mas.InitListener() {
                    @Override
                    public void onMasInitSuccessful() {
                        handleInitSuccess();
                    }

                    @Override
                    public void onMasInitSuccessful(Yodo1MasSdkConfiguration configuration) {
                        handleInitSuccess();
                    }

                    @Override
                    public void onMasInitFailed(@NonNull Yodo1MasError error) {
                        Log.e(TAG, "Yodo1 MAS SDK init failed: " + error.getMessage());
                        dispatchEvent("onSdkInitFailed", error.getCode() + "|" + error.getMessage());
                    }
                });
            }
        });
    }

    private boolean initCompleted = false;

    private void handleInitSuccess() {
        if (initCompleted) return;
        initCompleted = true;

        Log.d(TAG, "Yodo1 MAS SDK initialized successfully");
        dispatchEvent("onSdkInitSuccess", "");

        // Set up all ad listeners after successful init
        setupInterstitialListeners();
        setupRewardedListeners();
        setupAppOpenListeners();

        // Pre-load ads
        Yodo1MasAppOpenAd.getInstance().loadAd(activity);
        Yodo1MasRewardAd.getInstance().loadAd(activity);
        Yodo1MasInterstitialAd.getInstance().loadAd(activity);
    }

    // ============ Privacy / Legal ============

    public void setCOPPA(boolean enabled) {
        Yodo1Mas.getInstance().setCOPPA(enabled);
    }

    public void setGDPR(boolean consent) {
        Yodo1Mas.getInstance().setGDPR(consent);
    }

    public void setCCPA(boolean optOut) {
        Yodo1Mas.getInstance().setCCPA(optOut);
    }

    // ============ Banner Ads ============

    public void loadBannerAd(final String placement) {
        if (activity == null) return;

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (bannerAdView == null) {
                    bannerAdView = new Yodo1MasBannerAdView(activity);
                    bannerAdView.setAdSize(Yodo1MasBannerAdSize.Banner);

                    bannerAdView.setAdListener(new Yodo1MasBannerAdListener() {
                        @Override
                        public void onBannerAdLoaded(Yodo1MasBannerAdView ad) {
                            Log.d(TAG, "Banner ad loaded");
                            dispatchEvent("onBannerAdLoaded", "");
                        }

                        @Override
                        public void onBannerAdFailedToLoad(Yodo1MasBannerAdView ad, @NonNull Yodo1MasError error) {
                            Log.e(TAG, "Banner ad failed to load: " + error.getMessage());
                            dispatchEvent("onBannerAdFailedToLoad", error.getCode() + "|" + error.getMessage());
                        }

                        @Override
                        public void onBannerAdOpened(Yodo1MasBannerAdView ad) {
                            dispatchEvent("onBannerAdOpened", "");
                        }

                        @Override
                        public void onBannerAdFailedToOpen(Yodo1MasBannerAdView ad, @NonNull Yodo1MasError error) {
                            dispatchEvent("onBannerAdFailedToOpen", error.getCode() + "|" + error.getMessage());
                        }

                        @Override
                        public void onBannerAdClosed(Yodo1MasBannerAdView ad) {
                            dispatchEvent("onBannerAdClosed", "");
                        }
                    });

                    bannerAdView.setAdRevenueListener(new Yodo1MasBannerAdRevenueListener() {
                        @Override
                        public void onBannerAdPayRevenue(Yodo1MasBannerAdView ad, Yodo1MasAdValue adValue) {
                            dispatchAdRevenueEvent("banner", adValue);
                        }
                    });
                }

                bannerAdView.loadAd();
            }
        });
    }

    public void showBannerAd(final String placement, final int position) {
        if (activity == null || bannerAdView == null) return;

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                // Remove from current parent if already attached
                if (bannerAdView.getParent() != null) {
                    ((ViewGroup) bannerAdView.getParent()).removeView(bannerAdView);
                }

                // Add banner to activity's content view
                FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.WRAP_CONTENT,
                        FrameLayout.LayoutParams.WRAP_CONTENT
                );

                // Position: 0=TOP_CENTER, 1=BOTTOM_CENTER, 2=TOP_LEFT, 3=TOP_RIGHT, 4=BOTTOM_LEFT, 5=BOTTOM_RIGHT
                switch (position) {
                    case 0:
                        params.gravity = Gravity.TOP | Gravity.CENTER_HORIZONTAL;
                        break;
                    case 1:
                    default:
                        params.gravity = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
                        break;
                    case 2:
                        params.gravity = Gravity.TOP | Gravity.LEFT;
                        break;
                    case 3:
                        params.gravity = Gravity.TOP | Gravity.RIGHT;
                        break;
                    case 4:
                        params.gravity = Gravity.BOTTOM | Gravity.LEFT;
                        break;
                    case 5:
                        params.gravity = Gravity.BOTTOM | Gravity.RIGHT;
                        break;
                }

                ViewGroup rootView = (ViewGroup) activity.findViewById(android.R.id.content);
                rootView.addView(bannerAdView, params);

                bannerAdView.setVisibility(android.view.View.VISIBLE);
                bannerAdView.loadAd();
            }
        });
    }

    public void hideBannerAd() {
        if (activity == null || bannerAdView == null) return;

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                bannerAdView.setVisibility(android.view.View.GONE);
            }
        });
    }

    public void destroyBannerAd() {
        if (activity == null || bannerAdView == null) return;

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (bannerAdView.getParent() != null) {
                    ((ViewGroup) bannerAdView.getParent()).removeView(bannerAdView);
                }
                bannerAdView.destroy();
                bannerAdView = null;
            }
        });
    }

    public boolean isBannerAdLoaded() {
        return bannerAdView != null && bannerAdView.getParent() != null;
    }

    // ============ Interstitial Ads ============

    private void setupInterstitialListeners() {
        Yodo1MasInterstitialAd.getInstance().setAdListener(new Yodo1MasInterstitialAdListener() {
            @Override
            public void onInterstitialAdLoaded(Yodo1MasInterstitialAd ad) {
                Log.d(TAG, "Interstitial ad loaded");
                dispatchEvent("onInterstitialAdLoaded", "");
            }

            @Override
            public void onInterstitialAdFailedToLoad(Yodo1MasInterstitialAd ad, @NonNull Yodo1MasError error) {
                Log.e(TAG, "Interstitial ad failed to load: " + error.getMessage());
                dispatchEvent("onInterstitialAdFailedToLoad", error.getCode() + "|" + error.getMessage());
            }

            @Override
            public void onInterstitialAdOpened(Yodo1MasInterstitialAd ad) {
                dispatchEvent("onInterstitialAdOpened", "");
            }

            @Override
            public void onInterstitialAdFailedToOpen(Yodo1MasInterstitialAd ad, @NonNull Yodo1MasError error) {
                dispatchEvent("onInterstitialAdFailedToOpen", error.getCode() + "|" + error.getMessage());
            }

            @Override
            public void onInterstitialAdClosed(Yodo1MasInterstitialAd ad) {
                dispatchEvent("onInterstitialAdClosed", "");
                // Auto-reload after close
                Yodo1MasInterstitialAd.getInstance().loadAd(activity);
            }
        });

        Yodo1MasInterstitialAd.getInstance().setAdRevenueListener(new Yodo1MasInterstitialAdRevenueListener() {
            @Override
            public void onInterstitialAdPayRevenue(Yodo1MasInterstitialAd ad, Yodo1MasAdValue adValue) {
                dispatchAdRevenueEvent("interstitial", adValue);
            }
        });
    }

    public void loadInterstitialAd() {
        if (activity == null) return;

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Yodo1MasInterstitialAd.getInstance().loadAd(activity);
            }
        });
    }

    public void showInterstitialAd(final String placement) {
        if (activity == null) return;

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (Yodo1MasInterstitialAd.getInstance().isLoaded()) {
                    if (placement != null && !placement.isEmpty()) {
                        Yodo1MasInterstitialAd.getInstance().showAd(activity, placement);
                    } else {
                        Yodo1MasInterstitialAd.getInstance().showAd(activity);
                    }
                } else {
                    dispatchEvent("onInterstitialAdFailedToOpen", "Ad not loaded");
                }
            }
        });
    }

    public boolean isInterstitialAdLoaded() {
        return Yodo1MasInterstitialAd.getInstance().isLoaded();
    }

    // ============ Rewarded Video Ads ============

    private void setupRewardedListeners() {
        Yodo1MasRewardAd.getInstance().setAdListener(new Yodo1MasRewardAdListener() {
            @Override
            public void onRewardAdLoaded(Yodo1MasRewardAd ad) {
                Log.d(TAG, "Rewarded ad loaded");
                dispatchEvent("onRewardedAdLoaded", "");
            }

            @Override
            public void onRewardAdFailedToLoad(Yodo1MasRewardAd ad, @NonNull Yodo1MasError error) {
                Log.e(TAG, "Rewarded ad failed to load: " + error.getMessage());
                dispatchEvent("onRewardedAdFailedToLoad", error.getCode() + "|" + error.getMessage());
            }

            @Override
            public void onRewardAdOpened(Yodo1MasRewardAd ad) {
                dispatchEvent("onRewardedAdOpened", "");
            }

            @Override
            public void onRewardAdFailedToOpen(Yodo1MasRewardAd ad, @NonNull Yodo1MasError error) {
                dispatchEvent("onRewardedAdFailedToOpen", error.getCode() + "|" + error.getMessage());
            }

            @Override
            public void onRewardAdClosed(Yodo1MasRewardAd ad) {
                dispatchEvent("onRewardedAdClosed", "");
                // Auto-reload after close
                Yodo1MasRewardAd.getInstance().loadAd(activity);
            }

            @Override
            public void onRewardAdEarned(Yodo1MasRewardAd ad) {
                Log.d(TAG, "Rewarded ad earned reward");
                dispatchEvent("onRewardedAdEarned", "");
            }
        });

        Yodo1MasRewardAd.getInstance().setAdRevenueListener(new Yodo1MasRewardAdRevenueListener() {
            @Override
            public void onRewardAdPayRevenue(Yodo1MasRewardAd ad, Yodo1MasAdValue adValue) {
                dispatchAdRevenueEvent("rewarded", adValue);
            }
        });
    }

    public void loadRewardedAd() {
        if (activity == null) return;

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Yodo1MasRewardAd.getInstance().loadAd(activity);
            }
        });
    }

    public void showRewardedAd(final String placement) {
        if (activity == null) return;

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (Yodo1MasRewardAd.getInstance().isLoaded()) {
                    if (placement != null && !placement.isEmpty()) {
                        Yodo1MasRewardAd.getInstance().showAd(activity, placement);
                    } else {
                        Yodo1MasRewardAd.getInstance().showAd(activity);
                    }
                } else {
                    dispatchEvent("onRewardedAdFailedToOpen", "Ad not loaded");
                }
            }
        });
    }

    public boolean isRewardedAdLoaded() {
        return Yodo1MasRewardAd.getInstance().isLoaded();
    }

    // ============ App Open Ads ============

    private void setupAppOpenListeners() {
        Yodo1MasAppOpenAd.getInstance().setAdListener(new Yodo1MasAppOpenAdListener() {
            @Override
            public void onAppOpenAdLoaded(Yodo1MasAppOpenAd ad) {
                Log.d(TAG, "App Open ad loaded");
                dispatchEvent("onAppOpenAdLoaded", "");
            }

            @Override
            public void onAppOpenAdFailedToLoad(Yodo1MasAppOpenAd ad, @NonNull Yodo1MasError error) {
                Log.e(TAG, "App Open ad failed to load: " + error.getMessage());
                dispatchEvent("onAppOpenAdFailedToLoad", error.getCode() + "|" + error.getMessage());
                // Reload on failure
                Yodo1MasAppOpenAd.getInstance().loadAd(activity);
            }

            @Override
            public void onAppOpenAdOpened(Yodo1MasAppOpenAd ad) {
                dispatchEvent("onAppOpenAdOpened", "");
            }

            @Override
            public void onAppOpenAdFailedToOpen(Yodo1MasAppOpenAd ad, @NonNull Yodo1MasError error) {
                dispatchEvent("onAppOpenAdFailedToOpen", error.getCode() + "|" + error.getMessage());
                // Reload on failure
                Yodo1MasAppOpenAd.getInstance().loadAd(activity);
            }

            @Override
            public void onAppOpenAdClosed(Yodo1MasAppOpenAd ad) {
                dispatchEvent("onAppOpenAdClosed", "");
                // Auto-reload after close
                Yodo1MasAppOpenAd.getInstance().loadAd(activity);
            }
        });

        Yodo1MasAppOpenAd.getInstance().setAdRevenueListener(new Yodo1MasAppOpenAdRevenueListener() {
            @Override
            public void onAppOpenAdPayRevenue(Yodo1MasAppOpenAd ad, Yodo1MasAdValue adValue) {
                dispatchAdRevenueEvent("appopen", adValue);
            }
        });
    }

    public void loadAppOpenAd() {
        if (activity == null) return;

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Yodo1MasAppOpenAd.getInstance().loadAd(activity);
            }
        });
    }

    public void showAppOpenAd(final String placement) {
        if (activity == null) return;

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (Yodo1MasAppOpenAd.getInstance().isLoaded()) {
                    if (placement != null && !placement.isEmpty()) {
                        Yodo1MasAppOpenAd.getInstance().showAd(activity, placement);
                    } else {
                        Yodo1MasAppOpenAd.getInstance().showAd(activity);
                    }
                } else {
                    dispatchEvent("onAppOpenAdFailedToOpen", "Ad not loaded");
                }
            }
        });
    }

    public boolean isAppOpenAdLoaded() {
        return Yodo1MasAppOpenAd.getInstance().isLoaded();
    }

    // ============ Utility ============

    private int dpToPx(int dp) {
        float density = activity.getResources().getDisplayMetrics().density;
        return Math.round(dp * density);
    }
}
