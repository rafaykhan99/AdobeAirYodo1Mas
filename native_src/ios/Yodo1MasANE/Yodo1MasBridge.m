/**
 * Yodo1MasBridge.m
 *
 * Implementation of the Yodo1 MAS bridge for Adobe AIR iOS native extension.
 *
 * This class wraps all Yodo1MasCore SDK calls and dispatches FRE status events
 * back to ActionScript. The event names and data formats match the Android
 * Yodo1MasBridge.java implementation exactly, so the same AS3 event handling
 * code works cross-platform.
 *
 * Event data formats:
 *   - Success events: ""  (empty string)
 *   - Failure events: "errorCode|errorMessage"
 *   - Revenue events: "adType|revenue|currency|precision"
 */

#import "Yodo1MasBridge.h"

// Yodo1 MAS SDK Imports
#import <Yodo1MasCore/Yodo1Mas.h>
#import <Yodo1MasCore/Yodo1MasAppOpenAd.h>
#import <Yodo1MasCore/Yodo1MasInterstitialAd.h>
#import <Yodo1MasCore/Yodo1MasRewardAd.h>
#import <Yodo1MasCore/Yodo1MasBannerAdView.h>
#import <Yodo1MasCore/Yodo1MasError.h>
#import <Yodo1MasCore/Yodo1MasAdValue.h>

static NSString *const TAG = @"Yodo1MasANE";

@interface Yodo1MasBridge () <Yodo1MasAppOpenAdDelegate,
                               Yodo1MasInterstitialDelegate,
                               Yodo1MasRewardDelegate,
                               Yodo1MasBannerAdViewDelegate,
                               Yodo1MasAppOpenAdRevenueDelegate,
                               Yodo1MasInterstitialAdRevenueDelegate,
                               Yodo1MasRewardAdRevenueDelegate,
                               Yodo1MasBannerAdRevenueDelegate>

@property (nonatomic, assign) BOOL initCompleted;
@property (nonatomic, assign) BOOL initCallbackFired;
@property (nonatomic, strong) Yodo1MasBannerAdView *bannerAdView;
@property (nonatomic, assign) int currentBannerPosition;

@end

@implementation Yodo1MasBridge

+ (instancetype)sharedInstance {
    static Yodo1MasBridge *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[Yodo1MasBridge alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _initCompleted = NO;
        _initCallbackFired = NO;
        _currentBannerPosition = 1; // BOTTOM_CENTER default
    }
    return self;
}

#pragma mark - Event Dispatching

- (void)dispatchEvent:(NSString *)code level:(NSString *)level {
    if (_freContext != nil) {
        const uint8_t *cCode = (const uint8_t *)[code UTF8String];
        const uint8_t *cLevel = (const uint8_t *)[(level ?: @"") UTF8String];
        FREDispatchStatusEventAsync(_freContext, cCode, cLevel);
    }
}

- (void)dispatchAdRevenueEvent:(NSString *)adType adValue:(Yodo1MasAdValue *)adValue {
    if (adValue != nil) {
        NSString *data = [NSString stringWithFormat:@"%@|%f|%@|%@",
                          adType,
                          adValue.revenue,
                          adValue.currency ?: @"USD",
                          adValue.revenuePrecision ?: @""];
        [self dispatchEvent:@"onAdRevenue" level:data];
    }
}

#pragma mark - SDK Init

- (void)initSdkWithAppKey:(NSString *)appKey {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Set auto-delay for all ad types before init
        [Yodo1MasAppOpenAd sharedInstance].autoDelayIfLoadFail = YES;
        [Yodo1MasRewardAd sharedInstance].autoDelayIfLoadFail = YES;
        [Yodo1MasInterstitialAd sharedInstance].autoDelayIfLoadFail = YES;

        if (self.initCompleted) {
            // Already initialized, just fire success again
            [self dispatchEvent:@"onSdkInitSuccess" level:@""];
            return;
        }

        self.initCallbackFired = NO;

        [[Yodo1Mas sharedInstance] initMasWithAppKey:appKey
                                            successful:^{
            if (self.initCallbackFired) return;
            self.initCallbackFired = YES;
            [self handleInitSuccess];
        } fail:^(NSError *error) {
            if (self.initCallbackFired) return;
            self.initCallbackFired = YES;
            self.initCompleted = NO;

            NSString *errData = [NSString stringWithFormat:@"%ld|%@",
                                 (long)error.code,
                                 error.localizedDescription ?: @"MAS init failed"];
            NSLog(@"%@ Yodo1 MAS SDK init failed: %@", TAG, errData);
            [self dispatchEvent:@"onSdkInitFailed" level:errData];
        }];
    });
}

- (void)handleInitSuccess {
    if (self.initCompleted) return;
    self.initCompleted = YES;

    NSLog(@"%@ Yodo1 MAS SDK initialized successfully", TAG);
    [self dispatchEvent:@"onSdkInitSuccess" level:@""];

    // Set up all ad listeners
    [self setupInterstitialListeners];
    [self setupRewardedListeners];
    [self setupAppOpenListeners];

    // Pre-load ads
    [[Yodo1MasAppOpenAd sharedInstance] loadAd];
    [[Yodo1MasRewardAd sharedInstance] loadAd];
    [[Yodo1MasInterstitialAd sharedInstance] loadAd];
}

#pragma mark - Privacy / Legal

- (void)setCOPPA:(BOOL)enabled {
    [Yodo1Mas sharedInstance].isCOPPAAgeRestricted = enabled;
}

- (void)setGDPR:(BOOL)consent {
    [Yodo1Mas sharedInstance].isGDPRUserConsent = consent;
}

- (void)setCCPA:(BOOL)optOut {
    [Yodo1Mas sharedInstance].isCCPADoNotSell = optOut;
}

#pragma mark - Banner Ads

- (void)loadBannerAd:(NSString *)placement {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bannerAdView == nil) {
            self.bannerAdView = [[Yodo1MasBannerAdView alloc] init];
            self.bannerAdView.adDelegate = self;
            self.bannerAdView.adRevenueDelegate = self;
        }
        [self.bannerAdView loadAd];
    });
}

- (void)showBannerAd:(NSString *)placement position:(int)position {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bannerAdView == nil) return;

        self.currentBannerPosition = position;

        // Remove from current superview if already attached
        [self.bannerAdView removeFromSuperview];

        // Get root view controller's view
        UIViewController *rootVC = [self rootViewController];
        if (rootVC == nil) return;

        UIView *parentView = rootVC.view;
        [parentView addSubview:self.bannerAdView];

        // Disable autoresizing mask to use auto layout
        self.bannerAdView.translatesAutoresizingMaskIntoConstraints = NO;

        // Banner standard size: 320x50
        [NSLayoutConstraint activateConstraints:@[
            [self.bannerAdView.widthAnchor constraintEqualToConstant:320],
            [self.bannerAdView.heightAnchor constraintEqualToConstant:50]
        ]];

        // Position: 0=TOP_CENTER, 1=BOTTOM_CENTER, 2=TOP_LEFT, 3=TOP_RIGHT, 4=BOTTOM_LEFT, 5=BOTTOM_RIGHT
        UILayoutGuide *safeArea = parentView.safeAreaLayoutGuide;

        switch (position) {
            case 0: // TOP_CENTER
                [NSLayoutConstraint activateConstraints:@[
                    [self.bannerAdView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
                    [self.bannerAdView.centerXAnchor constraintEqualToAnchor:parentView.centerXAnchor]
                ]];
                break;
            case 2: // TOP_LEFT
                [NSLayoutConstraint activateConstraints:@[
                    [self.bannerAdView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
                    [self.bannerAdView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor]
                ]];
                break;
            case 3: // TOP_RIGHT
                [NSLayoutConstraint activateConstraints:@[
                    [self.bannerAdView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
                    [self.bannerAdView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor]
                ]];
                break;
            case 4: // BOTTOM_LEFT
                [NSLayoutConstraint activateConstraints:@[
                    [self.bannerAdView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],
                    [self.bannerAdView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor]
                ]];
                break;
            case 5: // BOTTOM_RIGHT
                [NSLayoutConstraint activateConstraints:@[
                    [self.bannerAdView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],
                    [self.bannerAdView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor]
                ]];
                break;
            case 1: // BOTTOM_CENTER (default)
            default:
                [NSLayoutConstraint activateConstraints:@[
                    [self.bannerAdView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],
                    [self.bannerAdView.centerXAnchor constraintEqualToAnchor:parentView.centerXAnchor]
                ]];
                break;
        }

        self.bannerAdView.hidden = NO;
        [self.bannerAdView loadAd];
    });
}

- (void)hideBannerAd {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bannerAdView != nil) {
            self.bannerAdView.hidden = YES;
        }
    });
}

- (void)destroyBannerAd {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bannerAdView != nil) {
            [self.bannerAdView removeFromSuperview];
            [self.bannerAdView destroy];
            self.bannerAdView = nil;
        }
    });
}

- (BOOL)isBannerAdLoaded {
    return self.bannerAdView != nil && self.bannerAdView.superview != nil;
}

#pragma mark - Yodo1MasBannerAdViewDelegate

- (void)onBannerAdLoaded:(Yodo1MasBannerAdView *)ad {
    NSLog(@"%@ Banner ad loaded", TAG);
    [self dispatchEvent:@"onBannerAdLoaded" level:@""];
}

- (void)onBannerAdFailedToLoad:(Yodo1MasBannerAdView *)ad withError:(Yodo1MasError *)error {
    NSLog(@"%@ Banner ad failed to load: %@", TAG, error.localizedDescription);
    NSString *data = [NSString stringWithFormat:@"%ld|%@", (long)error.code, error.localizedDescription ?: @""];
    [self dispatchEvent:@"onBannerAdFailedToLoad" level:data];
}

- (void)onBannerAdOpened:(Yodo1MasBannerAdView *)ad {
    [self dispatchEvent:@"onBannerAdOpened" level:@""];
}

- (void)onBannerAdFailedToOpen:(Yodo1MasBannerAdView *)ad withError:(Yodo1MasError *)error {
    NSString *data = [NSString stringWithFormat:@"%ld|%@", (long)error.code, error.localizedDescription ?: @""];
    [self dispatchEvent:@"onBannerAdFailedToOpen" level:data];
}

- (void)onBannerAdClosed:(Yodo1MasBannerAdView *)ad {
    [self dispatchEvent:@"onBannerAdClosed" level:@""];
}

- (void)onBannerAdPayRevenue:(Yodo1MasBannerAdView *)ad withAdValue:(Yodo1MasAdValue *)adValue {
    [self dispatchAdRevenueEvent:@"banner" adValue:adValue];
}

#pragma mark - Interstitial Ads

- (void)setupInterstitialListeners {
    [Yodo1MasInterstitialAd sharedInstance].adDelegate = self;
    [Yodo1MasInterstitialAd sharedInstance].adRevenueDelegate = self;
}

- (void)loadInterstitialAd {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Yodo1MasInterstitialAd sharedInstance] loadAd];
    });
}

- (void)showInterstitialAd:(NSString *)placement {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[Yodo1MasInterstitialAd sharedInstance] isLoaded]) {
            if (placement != nil && placement.length > 0) {
                [[Yodo1MasInterstitialAd sharedInstance] showAdWithPlacement:placement];
            } else {
                [[Yodo1MasInterstitialAd sharedInstance] showAd];
            }
        } else {
            [self dispatchEvent:@"onInterstitialAdFailedToOpen" level:@"Ad not loaded"];
        }
    });
}

- (BOOL)isInterstitialAdLoaded {
    return [[Yodo1MasInterstitialAd sharedInstance] isLoaded];
}

#pragma mark - Yodo1MasInterstitialDelegate

- (void)onInterstitialAdLoaded:(Yodo1MasInterstitialAd *)ad {
    NSLog(@"%@ Interstitial ad loaded", TAG);
    [self dispatchEvent:@"onInterstitialAdLoaded" level:@""];
}

- (void)onInterstitialAdFailedToLoad:(Yodo1MasInterstitialAd *)ad withError:(Yodo1MasError *)error {
    NSLog(@"%@ Interstitial ad failed to load: %@", TAG, error.localizedDescription);
    NSString *data = [NSString stringWithFormat:@"%ld|%@", (long)error.code, error.localizedDescription ?: @""];
    [self dispatchEvent:@"onInterstitialAdFailedToLoad" level:data];
}

- (void)onInterstitialAdOpened:(Yodo1MasInterstitialAd *)ad {
    [self dispatchEvent:@"onInterstitialAdOpened" level:@""];
}

- (void)onInterstitialAdFailedToOpen:(Yodo1MasInterstitialAd *)ad withError:(Yodo1MasError *)error {
    NSString *data = [NSString stringWithFormat:@"%ld|%@", (long)error.code, error.localizedDescription ?: @""];
    [self dispatchEvent:@"onInterstitialAdFailedToOpen" level:data];
}

- (void)onInterstitialAdClosed:(Yodo1MasInterstitialAd *)ad {
    [self dispatchEvent:@"onInterstitialAdClosed" level:@""];
    // Auto-reload after close
    [[Yodo1MasInterstitialAd sharedInstance] loadAd];
}

- (void)onInterstitialAdPayRevenue:(Yodo1MasInterstitialAd *)ad withAdValue:(Yodo1MasAdValue *)adValue {
    [self dispatchAdRevenueEvent:@"interstitial" adValue:adValue];
}

#pragma mark - Rewarded Ads

- (void)setupRewardedListeners {
    [Yodo1MasRewardAd sharedInstance].adDelegate = self;
    [Yodo1MasRewardAd sharedInstance].adRevenueDelegate = self;
}

- (void)loadRewardedAd {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Yodo1MasRewardAd sharedInstance] loadAd];
    });
}

- (void)showRewardedAd:(NSString *)placement {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[Yodo1MasRewardAd sharedInstance] isLoaded]) {
            if (placement != nil && placement.length > 0) {
                [[Yodo1MasRewardAd sharedInstance] showAdWithPlacement:placement];
            } else {
                [[Yodo1MasRewardAd sharedInstance] showAd];
            }
        } else {
            [self dispatchEvent:@"onRewardedAdFailedToOpen" level:@"Ad not loaded"];
        }
    });
}

- (BOOL)isRewardedAdLoaded {
    return [[Yodo1MasRewardAd sharedInstance] isLoaded];
}

#pragma mark - Yodo1MasRewardDelegate

- (void)onRewardAdLoaded:(Yodo1MasRewardAd *)ad {
    NSLog(@"%@ Rewarded ad loaded", TAG);
    [self dispatchEvent:@"onRewardedAdLoaded" level:@""];
}

- (void)onRewardAdFailedToLoad:(Yodo1MasRewardAd *)ad withError:(Yodo1MasError *)error {
    NSLog(@"%@ Rewarded ad failed to load: %@", TAG, error.localizedDescription);
    NSString *data = [NSString stringWithFormat:@"%ld|%@", (long)error.code, error.localizedDescription ?: @""];
    [self dispatchEvent:@"onRewardedAdFailedToLoad" level:data];
}

- (void)onRewardAdOpened:(Yodo1MasRewardAd *)ad {
    [self dispatchEvent:@"onRewardedAdOpened" level:@""];
}

- (void)onRewardAdFailedToOpen:(Yodo1MasRewardAd *)ad withError:(Yodo1MasError *)error {
    NSString *data = [NSString stringWithFormat:@"%ld|%@", (long)error.code, error.localizedDescription ?: @""];
    [self dispatchEvent:@"onRewardedAdFailedToOpen" level:data];
}

- (void)onRewardAdClosed:(Yodo1MasRewardAd *)ad {
    [self dispatchEvent:@"onRewardedAdClosed" level:@""];
    // Auto-reload after close
    [[Yodo1MasRewardAd sharedInstance] loadAd];
}

- (void)onRewardAdEarned:(Yodo1MasRewardAd *)ad {
    NSLog(@"%@ Rewarded ad earned reward", TAG);
    [self dispatchEvent:@"onRewardedAdEarned" level:@""];
}

- (void)onRewardAdPayRevenue:(Yodo1MasRewardAd *)ad withAdValue:(Yodo1MasAdValue *)adValue {
    [self dispatchAdRevenueEvent:@"rewarded" adValue:adValue];
}

#pragma mark - App Open Ads

- (void)setupAppOpenListeners {
    [Yodo1MasAppOpenAd sharedInstance].adDelegate = self;
    [Yodo1MasAppOpenAd sharedInstance].adRevenueDelegate = self;
}

- (void)loadAppOpenAd {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Yodo1MasAppOpenAd sharedInstance] loadAd];
    });
}

- (void)showAppOpenAd:(NSString *)placement {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[Yodo1MasAppOpenAd sharedInstance] isLoaded]) {
            if (placement != nil && placement.length > 0) {
                [[Yodo1MasAppOpenAd sharedInstance] showAdWithPlacement:placement];
            } else {
                [[Yodo1MasAppOpenAd sharedInstance] showAd];
            }
        } else {
            [self dispatchEvent:@"onAppOpenAdFailedToOpen" level:@"Ad not loaded"];
        }
    });
}

- (BOOL)isAppOpenAdLoaded {
    return [[Yodo1MasAppOpenAd sharedInstance] isLoaded];
}

#pragma mark - Yodo1MasAppOpenAdDelegate

- (void)onAppOpenAdLoaded:(Yodo1MasAppOpenAd *)ad {
    NSLog(@"%@ App Open ad loaded", TAG);
    [self dispatchEvent:@"onAppOpenAdLoaded" level:@""];
}

- (void)onAppOpenAdFailedToLoad:(Yodo1MasAppOpenAd *)ad withError:(Yodo1MasError *)error {
    NSLog(@"%@ App Open ad failed to load: %@", TAG, error.localizedDescription);
    NSString *data = [NSString stringWithFormat:@"%ld|%@", (long)error.code, error.localizedDescription ?: @""];
    [self dispatchEvent:@"onAppOpenAdFailedToLoad" level:data];
    // Reload on failure
    [[Yodo1MasAppOpenAd sharedInstance] loadAd];
}

- (void)onAppOpenAdOpened:(Yodo1MasAppOpenAd *)ad {
    [self dispatchEvent:@"onAppOpenAdOpened" level:@""];
}

- (void)onAppOpenAdFailedToOpen:(Yodo1MasAppOpenAd *)ad withError:(Yodo1MasError *)error {
    NSString *data = [NSString stringWithFormat:@"%ld|%@", (long)error.code, error.localizedDescription ?: @""];
    [self dispatchEvent:@"onAppOpenAdFailedToOpen" level:data];
    // Reload on failure
    [[Yodo1MasAppOpenAd sharedInstance] loadAd];
}

- (void)onAppOpenAdClosed:(Yodo1MasAppOpenAd *)ad {
    [self dispatchEvent:@"onAppOpenAdClosed" level:@""];
    // Auto-reload after close
    [[Yodo1MasAppOpenAd sharedInstance] loadAd];
}

- (void)onAppOpenAdPayRevenue:(Yodo1MasAppOpenAd *)ad withAdValue:(Yodo1MasAdValue *)adValue {
    [self dispatchAdRevenueEvent:@"appopen" adValue:adValue];
}

#pragma mark - Utility

- (UIViewController *)rootViewController {
    UIWindowScene *windowScene = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            windowScene = (UIWindowScene *)scene;
            break;
        }
    }
    if (windowScene == nil) {
        // Fallback for older setup
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                windowScene = (UIWindowScene *)scene;
                break;
            }
        }
    }
    if (windowScene != nil) {
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window.rootViewController;
            }
        }
    }
    return nil;
}

#pragma mark - Cleanup

- (void)dispose {
    [self destroyBannerAd];
    _freContext = nil;
}

@end
