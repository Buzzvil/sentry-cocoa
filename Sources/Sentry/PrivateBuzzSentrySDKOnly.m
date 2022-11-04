#import "PrivateBuzzSentrySDKOnly.h"
#import "BuzzSentryClient.h"
#import "BuzzSentryDebugImageProvider.h"
#import "BuzzSentryHub+Private.h"
#import "BuzzSentryInstallation.h"
#import "BuzzSentryMeta.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentrySerialization.h"
#import <BuzzSentryDependencyContainer.h>
#import <BuzzSentryFramesTracker.h>

@implementation PrivateBuzzSentrySDKOnly

static SentryOnAppStartMeasurementAvailable _onAppStartMeasurementAvailable;
static BOOL _appStartMeasurementHybridSDKMode = NO;
#if SENTRY_HAS_UIKIT
static BOOL _framesTrackingMeasurementHybridSDKMode = NO;
#endif

+ (void)storeEnvelope:(BuzzSentryEnvelope *)envelope
{
    [BuzzSentrySDK storeEnvelope:envelope];
}

+ (void)captureEnvelope:(BuzzSentryEnvelope *)envelope
{
    [BuzzSentrySDK captureEnvelope:envelope];
}

+ (nullable BuzzSentryEnvelope *)envelopeWithData:(NSData *)data
{
    return [BuzzSentrySerialization envelopeWithData:data];
}

+ (NSArray<BuzzSentryDebugMeta *> *)getDebugImages
{
    return [[BuzzSentryDependencyContainer sharedInstance].debugImageProvider getDebugImages];
}

+ (nullable BuzzSentryAppStartMeasurement *)appStartMeasurement
{
    return [BuzzSentrySDK getAppStartMeasurement];
}

+ (NSString *)installationID
{
    return [BuzzSentryInstallation id];
}

+ (BuzzSentryOptions *)options
{
    BuzzSentryOptions *options = [[BuzzSentrySDK currentHub] client].options;
    if (options != nil) {
        return options;
    }
    return [[BuzzSentryOptions alloc] init];
}

+ (SentryOnAppStartMeasurementAvailable)onAppStartMeasurementAvailable
{
    return _onAppStartMeasurementAvailable;
}

+ (void)setOnAppStartMeasurementAvailable:
    (SentryOnAppStartMeasurementAvailable)onAppStartMeasurementAvailable
{
    _onAppStartMeasurementAvailable = onAppStartMeasurementAvailable;
}

+ (BOOL)appStartMeasurementHybridSDKMode
{
    return _appStartMeasurementHybridSDKMode;
}

+ (void)setAppStartMeasurementHybridSDKMode:(BOOL)appStartMeasurementHybridSDKMode
{
    _appStartMeasurementHybridSDKMode = appStartMeasurementHybridSDKMode;
}

+ (void)setSdkName:(NSString *)sdkName andVersionString:(NSString *)versionString
{
    BuzzSentryMeta.sdkName = sdkName;
    BuzzSentryMeta.versionString = versionString;
}

+ (void)setSdkName:(NSString *)sdkName
{
    BuzzSentryMeta.sdkName = sdkName;
}

+ (NSString *)getSdkName
{
    return BuzzSentryMeta.sdkName;
}

+ (NSString *)getSdkVersionString
{
    return BuzzSentryMeta.versionString;
}

#if SENTRY_HAS_UIKIT

+ (BOOL)framesTrackingMeasurementHybridSDKMode
{
    return _framesTrackingMeasurementHybridSDKMode;
}

+ (void)setFramesTrackingMeasurementHybridSDKMode:(BOOL)framesTrackingMeasurementHybridSDKMode
{
    _framesTrackingMeasurementHybridSDKMode = framesTrackingMeasurementHybridSDKMode;
}

+ (BOOL)isFramesTrackingRunning
{
    return [BuzzSentryFramesTracker sharedInstance].isRunning;
}

+ (BuzzSentryScreenFrames *)currentScreenFrames
{
    return [BuzzSentryFramesTracker sharedInstance].currentFrames;
}

#endif

@end