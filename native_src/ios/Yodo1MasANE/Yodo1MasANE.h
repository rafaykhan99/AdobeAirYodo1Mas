/**
 * Yodo1MasANE.h
 *
 * Adobe AIR Native Extension for Yodo1 MAS SDK (iOS).
 *
 * This is the main header for the iOS native extension.
 * It declares the FRE initializer/finalizer, context initializer/finalizer,
 * and all FREFunction implementations that map to ActionScript calls.
 *
 * The function names must exactly match those registered on the ActionScript
 * side in Yodo1MasFunNames.as (e.g. "yodo1mas_initSdk").
 */

#import <Foundation/Foundation.h>
#import "FlashRuntimeExtensions.h"

// ============ Extension lifecycle ============
void Yodo1MasExtInitializer(void **extDataToSet,
                            FREContextInitializer *ctxInitializerToSet,
                            FREContextFinalizer *ctxFinalizerToSet);

void Yodo1MasExtFinalizer(void *extData);

void Yodo1MasContextInitializer(void *extData,
                                const uint8_t *ctxType,
                                FREContext ctx,
                                uint32_t *numFunctionsToSet,
                                const FRENamedFunction **functionsToSet);

void Yodo1MasContextFinalizer(FREContext ctx);

// ============ FRE Functions ============

// SDK Init
FREObject yodo1mas_initSdk(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_setCOPPA(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_setGDPR(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_setCCPA(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);

// Banner
FREObject yodo1mas_loadBannerAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_showBannerAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_hideBannerAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_destroyBannerAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_isBannerAdLoaded(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);

// Interstitial
FREObject yodo1mas_loadInterstitialAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_showInterstitialAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_isInterstitialAdLoaded(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);

// Rewarded
FREObject yodo1mas_loadRewardedAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_showRewardedAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_isRewardedAdLoaded(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);

// App Open
FREObject yodo1mas_loadAppOpenAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_showAppOpenAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
FREObject yodo1mas_isAppOpenAdLoaded(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]);
