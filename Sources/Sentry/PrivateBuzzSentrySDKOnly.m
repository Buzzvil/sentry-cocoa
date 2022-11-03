#import "PrivateBuzzSentrySDKOnly.h"
#import "BuzzSentryClient.h"
#import "SentryDebugImageProvider.h"
#import "SentryHub+Private.h"
#import "SentryInstallation.h"
#import "BuzzSentryMeta.h"
#import "BuzzSentrySDK+Private.h"
#import "SentrySerialization.h"
#import <SentryDependencyContainer.h>
#import <BuzzSentryFramesTracker.h>

@implementation PrivateBuzzSentrySDKOnly

static SentryOnAppStartMeasurementAvailable _onAppStartMeasurementAvailable;
static BOOL _appStartMeasurementHybridSDKMode = NO;
#if SENTRY_HAS_UIKIT
static BOOL _framesTrackingMeasurementHybridSDKMode = NO;
#endif

+ (void)storeEnvelope:(BuzzSentryEnvelope *)envelope
{
    [SentrySDK storeEnvelope:envelope];
}

+ (void)captureEnvelope:(BuzzSentryEnvelope *)envelope
{
    [SentrySDK captureEnvelope:envelope];
}

+ (nullable BuzzSentryEnvelope *)envelopeWithData:(NSData *)data
{
    return [SentrySerialization envelopeWithData:data];
}

+ (NSArray<SentryDebugMeta *> *)getDebugImages
{
    return [[SentryDependencyContainer sharedInstance].debugImageProvider getDebugImages];
}

+ (nullable SentryAppStartMeasurement *)appStartMeasurement
{
    return [SentrySDK getAppStartMeasurement];
}

+ (NSString *)installationID
{
    return [SentryInstallation id];
}

+ (BuzzSentryOptions *)options
{
    BuzzSentryOptions *options = [[SentrySDK currentHub] client].options;
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

+ (SentryScreenFrames *)currentScreenFrames
{
    return [BuzzSentryFramesTracker sharedInstance].currentFrames;
}

#endif

@end
