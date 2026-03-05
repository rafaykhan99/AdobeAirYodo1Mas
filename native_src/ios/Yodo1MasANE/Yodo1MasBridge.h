/**
 * Yodo1MasBridge.h
 *
 * Bridge between the FRE C functions and the Yodo1 MAS Objective-C SDK.
 * Handles SDK initialization, privacy settings, and all ad operations
 * (banner, interstitial, rewarded, app open).
 *
 * Events are dispatched back to ActionScript through the FREContext using
 * FREDispatchStatusEventAsync(). The event "code" matches the AS3
 * Yodo1MasEvent constants, and "level" carries data (error info, revenue, etc.)
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FlashRuntimeExtensions.h"

@interface Yodo1MasBridge : NSObject

@property (nonatomic, assign) FREContext freContext;

+ (instancetype)sharedInstance;

// SDK Init
- (void)initSdkWithAppKey:(NSString *)appKey;
- (void)setCOPPA:(BOOL)enabled;
- (void)setGDPR:(BOOL)consent;
- (void)setCCPA:(BOOL)optOut;

// Banner
- (void)loadBannerAd:(NSString *)placement;
- (void)showBannerAd:(NSString *)placement position:(int)position;
- (void)hideBannerAd;
- (void)destroyBannerAd;
- (BOOL)isBannerAdLoaded;

// Interstitial
- (void)loadInterstitialAd;
- (void)showInterstitialAd:(NSString *)placement;
- (BOOL)isInterstitialAdLoaded;

// Rewarded
- (void)loadRewardedAd;
- (void)showRewardedAd:(NSString *)placement;
- (BOOL)isRewardedAdLoaded;

// App Open
- (void)loadAppOpenAd;
- (void)showAppOpenAd:(NSString *)placement;
- (BOOL)isAppOpenAdLoaded;

// Cleanup
- (void)dispose;

@end
