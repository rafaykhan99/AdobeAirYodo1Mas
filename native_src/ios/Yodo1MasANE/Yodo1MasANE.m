/**
 * Yodo1MasANE.m
 *
 * Adobe AIR Native Extension entry point for iOS.
 * Implements the FRE C API: extension initializer/finalizer,
 * context initializer/finalizer, and all individual FRE functions.
 *
 * Each FRE function:
 *   1. Extracts arguments from FREObject[] argv
 *   2. Calls the corresponding Yodo1MasBridge method
 *   3. Returns an FREObject (or NULL for void operations)
 *
 * The function names registered here MUST match Yodo1MasFunNames.as constants.
 */

#import "Yodo1MasANE.h"
#import "Yodo1MasBridge.h"

#define NUM_FUNCTIONS 18

// ============ Helper: FREObject → NSString ============
static NSString *FREObjectToNSString(FREObject obj) {
    if (obj == NULL) return nil;
    uint32_t length = 0;
    const uint8_t *value = NULL;
    FREResult result = FREGetObjectAsUTF8(obj, &length, &value);
    if (result != FRE_OK || value == NULL || length == 0) return nil;
    return [NSString stringWithUTF8String:(const char *)value];
}

// ============ Helper: FREObject → BOOL ============
static BOOL FREObjectToBool(FREObject obj) {
    if (obj == NULL) return NO;
    uint32_t value = 0;
    FREResult result = FREGetObjectAsBool(obj, &value);
    if (result != FRE_OK) return NO;
    return (value != 0);
}

// ============ Helper: FREObject → int ============
static int32_t FREObjectToInt(FREObject obj) {
    if (obj == NULL) return 0;
    int32_t value = 0;
    FREResult result = FREGetObjectAsInt32(obj, &value);
    if (result != FRE_OK) return 0;
    return value;
}

// ============ Helper: BOOL → FREObject ============
static FREObject BOOLToFREObject(BOOL value) {
    FREObject result = NULL;
    FRENewObjectFromBool((uint32_t)(value ? 1 : 0), &result);
    return result;
}

// ============ FRE Functions ============

FREObject yodo1mas_initSdk(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    NSString *appKey = (argc > 0) ? FREObjectToNSString(argv[0]) : nil;
    if (appKey == nil || appKey.length == 0) {
        NSLog(@"Yodo1MasANE: initSdk called without appKey");
        return NULL;
    }
    [[Yodo1MasBridge sharedInstance] initSdkWithAppKey:appKey];
    return NULL;
}

FREObject yodo1mas_setCOPPA(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    BOOL enabled = (argc > 0) ? FREObjectToBool(argv[0]) : NO;
    [[Yodo1MasBridge sharedInstance] setCOPPA:enabled];
    return NULL;
}

FREObject yodo1mas_setGDPR(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    BOOL consent = (argc > 0) ? FREObjectToBool(argv[0]) : NO;
    [[Yodo1MasBridge sharedInstance] setGDPR:consent];
    return NULL;
}

FREObject yodo1mas_setCCPA(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    BOOL optOut = (argc > 0) ? FREObjectToBool(argv[0]) : NO;
    [[Yodo1MasBridge sharedInstance] setCCPA:optOut];
    return NULL;
}

// Banner
FREObject yodo1mas_loadBannerAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    NSString *placement = (argc > 0) ? FREObjectToNSString(argv[0]) : nil;
    [[Yodo1MasBridge sharedInstance] loadBannerAd:placement];
    return NULL;
}

FREObject yodo1mas_showBannerAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    NSString *placement = (argc > 0) ? FREObjectToNSString(argv[0]) : nil;
    int position = (argc > 1) ? FREObjectToInt(argv[1]) : 1; // default BOTTOM_CENTER
    [[Yodo1MasBridge sharedInstance] showBannerAd:placement position:position];
    return NULL;
}

FREObject yodo1mas_hideBannerAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    [[Yodo1MasBridge sharedInstance] hideBannerAd];
    return NULL;
}

FREObject yodo1mas_destroyBannerAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    [[Yodo1MasBridge sharedInstance] destroyBannerAd];
    return NULL;
}

FREObject yodo1mas_isBannerAdLoaded(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    BOOL loaded = [[Yodo1MasBridge sharedInstance] isBannerAdLoaded];
    return BOOLToFREObject(loaded);
}

// Interstitial
FREObject yodo1mas_loadInterstitialAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    [[Yodo1MasBridge sharedInstance] loadInterstitialAd];
    return NULL;
}

FREObject yodo1mas_showInterstitialAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    NSString *placement = (argc > 0) ? FREObjectToNSString(argv[0]) : nil;
    [[Yodo1MasBridge sharedInstance] showInterstitialAd:placement];
    return NULL;
}

FREObject yodo1mas_isInterstitialAdLoaded(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    BOOL loaded = [[Yodo1MasBridge sharedInstance] isInterstitialAdLoaded];
    return BOOLToFREObject(loaded);
}

// Rewarded
FREObject yodo1mas_loadRewardedAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    [[Yodo1MasBridge sharedInstance] loadRewardedAd];
    return NULL;
}

FREObject yodo1mas_showRewardedAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    NSString *placement = (argc > 0) ? FREObjectToNSString(argv[0]) : nil;
    [[Yodo1MasBridge sharedInstance] showRewardedAd:placement];
    return NULL;
}

FREObject yodo1mas_isRewardedAdLoaded(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    BOOL loaded = [[Yodo1MasBridge sharedInstance] isRewardedAdLoaded];
    return BOOLToFREObject(loaded);
}

// App Open
FREObject yodo1mas_loadAppOpenAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    [[Yodo1MasBridge sharedInstance] loadAppOpenAd];
    return NULL;
}

FREObject yodo1mas_showAppOpenAd(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    NSString *placement = (argc > 0) ? FREObjectToNSString(argv[0]) : nil;
    [[Yodo1MasBridge sharedInstance] showAppOpenAd:placement];
    return NULL;
}

FREObject yodo1mas_isAppOpenAdLoaded(FREContext ctx, void *funcData, uint32_t argc, FREObject argv[]) {
    BOOL loaded = [[Yodo1MasBridge sharedInstance] isAppOpenAdLoaded];
    return BOOLToFREObject(loaded);
}

// ============ Context Initializer ============

void Yodo1MasContextInitializer(void *extData,
                                const uint8_t *ctxType,
                                FREContext ctx,
                                uint32_t *numFunctionsToSet,
                                const FRENamedFunction **functionsToSet) {
    // Set the FRE context on the bridge
    [Yodo1MasBridge sharedInstance].freContext = ctx;

    // Allocate and register all functions
    static FRENamedFunction functions[NUM_FUNCTIONS];

    functions[0].name  = (const uint8_t *)"yodo1mas_initSdk";
    functions[0].functionData = NULL;
    functions[0].function = &yodo1mas_initSdk;

    functions[1].name  = (const uint8_t *)"yodo1mas_setCOPPA";
    functions[1].functionData = NULL;
    functions[1].function = &yodo1mas_setCOPPA;

    functions[2].name  = (const uint8_t *)"yodo1mas_setGDPR";
    functions[2].functionData = NULL;
    functions[2].function = &yodo1mas_setGDPR;

    functions[3].name  = (const uint8_t *)"yodo1mas_setCCPA";
    functions[3].functionData = NULL;
    functions[3].function = &yodo1mas_setCCPA;

    functions[4].name  = (const uint8_t *)"yodo1mas_loadBannerAd";
    functions[4].functionData = NULL;
    functions[4].function = &yodo1mas_loadBannerAd;

    functions[5].name  = (const uint8_t *)"yodo1mas_showBannerAd";
    functions[5].functionData = NULL;
    functions[5].function = &yodo1mas_showBannerAd;

    functions[6].name  = (const uint8_t *)"yodo1mas_hideBannerAd";
    functions[6].functionData = NULL;
    functions[6].function = &yodo1mas_hideBannerAd;

    functions[7].name  = (const uint8_t *)"yodo1mas_destroyBannerAd";
    functions[7].functionData = NULL;
    functions[7].function = &yodo1mas_destroyBannerAd;

    functions[8].name  = (const uint8_t *)"yodo1mas_isBannerAdLoaded";
    functions[8].functionData = NULL;
    functions[8].function = &yodo1mas_isBannerAdLoaded;

    functions[9].name  = (const uint8_t *)"yodo1mas_loadInterstitialAd";
    functions[9].functionData = NULL;
    functions[9].function = &yodo1mas_loadInterstitialAd;

    functions[10].name = (const uint8_t *)"yodo1mas_showInterstitialAd";
    functions[10].functionData = NULL;
    functions[10].function = &yodo1mas_showInterstitialAd;

    functions[11].name = (const uint8_t *)"yodo1mas_isInterstitialAdLoaded";
    functions[11].functionData = NULL;
    functions[11].function = &yodo1mas_isInterstitialAdLoaded;

    functions[12].name = (const uint8_t *)"yodo1mas_loadRewardedAd";
    functions[12].functionData = NULL;
    functions[12].function = &yodo1mas_loadRewardedAd;

    functions[13].name = (const uint8_t *)"yodo1mas_showRewardedAd";
    functions[13].functionData = NULL;
    functions[13].function = &yodo1mas_showRewardedAd;

    functions[14].name = (const uint8_t *)"yodo1mas_isRewardedAdLoaded";
    functions[14].functionData = NULL;
    functions[14].function = &yodo1mas_isRewardedAdLoaded;

    functions[15].name = (const uint8_t *)"yodo1mas_loadAppOpenAd";
    functions[15].functionData = NULL;
    functions[15].function = &yodo1mas_loadAppOpenAd;

    functions[16].name = (const uint8_t *)"yodo1mas_showAppOpenAd";
    functions[16].functionData = NULL;
    functions[16].function = &yodo1mas_showAppOpenAd;

    functions[17].name = (const uint8_t *)"yodo1mas_isAppOpenAdLoaded";
    functions[17].functionData = NULL;
    functions[17].function = &yodo1mas_isAppOpenAdLoaded;

    *numFunctionsToSet = NUM_FUNCTIONS;
    *functionsToSet = functions;
}

// ============ Context Finalizer ============

void Yodo1MasContextFinalizer(FREContext ctx) {
    [[Yodo1MasBridge sharedInstance] dispose];
}

// ============ Extension Initializer ============

void Yodo1MasExtInitializer(void **extDataToSet,
                            FREContextInitializer *ctxInitializerToSet,
                            FREContextFinalizer *ctxFinalizerToSet) {
    *extDataToSet = NULL;
    *ctxInitializerToSet = &Yodo1MasContextInitializer;
    *ctxFinalizerToSet = &Yodo1MasContextFinalizer;
}

// ============ Extension Finalizer ============

void Yodo1MasExtFinalizer(void *extData) {
    // Nothing to clean up at extension level
}
