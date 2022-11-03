#import "SentrySDK.h"
#import "PrivateBuzzSentrySDKOnly.h"
#import "BuzzSentryAppStartMeasurement.h"
#import "BuzzSentryBreadcrumb.h"
#import "BuzzSentryClient+Private.h"
#import "SentryCrash.h"
#import "SentryDependencyContainer.h"
#import "SentryHub+Private.h"
#import "SentryLog.h"
#import "BuzzSentryMeta.h"
#import "BuzzSentryOptions+Private.h"
#import "SentryScope.h"

@interface
SentrySDK ()

@property (class) SentryHub *currentHub;

@end

NS_ASSUME_NONNULL_BEGIN
@implementation SentrySDK

static SentryHub *_Nullable currentHub;
static BOOL crashedLastRunCalled;
static BuzzSentryAppStartMeasurement *sentrySDKappStartMeasurement;
static NSObject *sentrySDKappStartMeasurementLock;

/**
 * @brief We need to keep track of the number of times @c +[startWith...] is called, because our OOM
 * reporting breaks if it's called more than once.
 * @discussion This doesn't just protect from multiple sequential calls to start the SDK, so we
 * can't simply @c dispatch_once the logic inside the start method; there is also a valid workflow
 * where a consumer could start the SDK, then call @c +[close] and then start again, and we want to
 * reenable the integrations.
 */
static NSUInteger startInvocations;

+ (void)initialize
{
    if (self == [SentrySDK class]) {
        sentrySDKappStartMeasurementLock = [[NSObject alloc] init];
        startInvocations = 0;
    }
}

+ (SentryHub *)currentHub
{
    @synchronized(self) {
        if (nil == currentHub) {
            currentHub = [[SentryHub alloc] initWithClient:nil andScope:nil];
        }
        return currentHub;
    }
}

+ (nullable BuzzSentryOptions *)options
{
    @synchronized(self) {
        return [[currentHub getClient] options];
    }
}

/** Internal, only needed for testing. */
+ (void)setCurrentHub:(nullable SentryHub *)hub
{
    @synchronized(self) {
        currentHub = hub;
    }
}

+ (nullable id<BuzzSentrySpan>)span
{
    return currentHub.scope.span;
}

+ (BOOL)isEnabled
{
    return currentHub != nil && [currentHub getClient] != nil;
}

+ (BOOL)crashedLastRunCalled
{
    return crashedLastRunCalled;
}

+ (void)setCrashedLastRunCalled:(BOOL)value
{
    crashedLastRunCalled = value;
}

/**
 * Not public, only for internal use.
 */
+ (void)setAppStartMeasurement:(nullable BuzzSentryAppStartMeasurement *)value
{
    @synchronized(sentrySDKappStartMeasurementLock) {
        sentrySDKappStartMeasurement = value;
    }
    if (PrivateBuzzSentrySDKOnly.onAppStartMeasurementAvailable) {
        PrivateBuzzSentrySDKOnly.onAppStartMeasurementAvailable(value);
    }
}

/**
 * Not public, only for internal use.
 */
+ (nullable BuzzSentryAppStartMeasurement *)getAppStartMeasurement
{
    @synchronized(sentrySDKappStartMeasurementLock) {
        return sentrySDKappStartMeasurement;
    }
}

/**
 * Not public, only for internal use.
 */
+ (NSUInteger)startInvocations
{
    return startInvocations;
}

/**
 * Only needed for testing.
 */
+ (void)setStartInvocations:(NSUInteger)value
{
    startInvocations = value;
}

+ (void)startWithOptions:(NSDictionary<NSString *, id> *)optionsDict
{
    NSError *error = nil;
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] initWithDict:optionsDict
                                                didFailWithError:&error];
    if (nil != error) {
        SENTRY_LOG_ERROR(@"Error while initializing the SDK");
        SENTRY_LOG_ERROR(@"%@", error);
    } else {
        [SentrySDK startWithOptionsObject:options];
    }
}

+ (void)startWithOptionsObject:(BuzzSentryOptions *)options
{
    startInvocations++;

    [SentryLog configure:options.debug diagnosticLevel:options.diagnosticLevel];

    BuzzSentryClient *newClient = [[BuzzSentryClient alloc] initWithOptions:options];
    [newClient.fileManager moveAppStateToPreviousAppState];

    // The Hub needs to be initialized with a client so that closing a session
    // can happen.
    [SentrySDK setCurrentHub:[[SentryHub alloc] initWithClient:newClient andScope:nil]];
    SENTRY_LOG_DEBUG(@"SDK initialized! Version: %@", BuzzSentryMeta.versionString);
    [SentrySDK installIntegrations];
}

+ (void)startWithConfigureOptions:(void (^)(BuzzSentryOptions *options))configureOptions
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    configureOptions(options);
    [SentrySDK startWithOptionsObject:options];
}

+ (void)captureCrashEvent:(BuzzSentryEvent *)event
{
    [SentrySDK.currentHub captureCrashEvent:event];
}

+ (void)captureCrashEvent:(BuzzSentryEvent *)event withScope:(SentryScope *)scope
{
    [SentrySDK.currentHub captureCrashEvent:event withScope:scope];
}

+ (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event
{
    return [SentrySDK captureEvent:event withScope:SentrySDK.currentHub.scope];
}

+ (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event withScopeBlock:(void (^)(SentryScope *))block
{
    SentryScope *scope = [[SentryScope alloc] initWithScope:SentrySDK.currentHub.scope];
    block(scope);
    return [SentrySDK captureEvent:event withScope:scope];
}

+ (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event withScope:(SentryScope *)scope
{
    return [SentrySDK.currentHub captureEvent:event withScope:scope];
}

+ (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name operation:(NSString *)operation
{
    return [self startTransactionWithName:name
                               nameSource:kBuzzSentryTransactionNameSourceCustom
                                operation:operation];
}

+ (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
                                nameSource:(BuzzSentryTransactionNameSource)source
                                 operation:(NSString *)operation
{
    return [SentrySDK.currentHub startTransactionWithName:name
                                               nameSource:source
                                                operation:operation];
}

+ (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
                                 operation:(NSString *)operation
                               bindToScope:(BOOL)bindToScope
{
    return [self startTransactionWithName:name
                               nameSource:kBuzzSentryTransactionNameSourceCustom
                                operation:operation
                              bindToScope:bindToScope];
}

+ (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
                                nameSource:(BuzzSentryTransactionNameSource)source
                                 operation:(NSString *)operation
                               bindToScope:(BOOL)bindToScope
{
    return [SentrySDK.currentHub startTransactionWithName:name
                                               nameSource:source
                                                operation:operation
                                              bindToScope:bindToScope];
}

+ (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
{
    return [SentrySDK.currentHub startTransactionWithContext:transactionContext];
}

+ (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
{
    return [SentrySDK.currentHub startTransactionWithContext:transactionContext
                                                 bindToScope:bindToScope];
}

+ (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
{
    return [SentrySDK.currentHub startTransactionWithContext:transactionContext
                                                 bindToScope:bindToScope
                                       customSamplingContext:customSamplingContext];
}

+ (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
{
    return [SentrySDK.currentHub startTransactionWithContext:transactionContext
                                       customSamplingContext:customSamplingContext];
}

+ (BuzzSentryId *)captureError:(NSError *)error
{
    return [SentrySDK captureError:error withScope:SentrySDK.currentHub.scope];
}

+ (BuzzSentryId *)captureError:(NSError *)error withScopeBlock:(void (^)(SentryScope *_Nonnull))block
{
    SentryScope *scope = [[SentryScope alloc] initWithScope:SentrySDK.currentHub.scope];
    block(scope);
    return [SentrySDK captureError:error withScope:scope];
}

+ (BuzzSentryId *)captureError:(NSError *)error withScope:(SentryScope *)scope
{
    return [SentrySDK.currentHub captureError:error withScope:scope];
}

+ (BuzzSentryId *)captureException:(NSException *)exception
{
    return [SentrySDK captureException:exception withScope:SentrySDK.currentHub.scope];
}

+ (BuzzSentryId *)captureException:(NSException *)exception
                withScopeBlock:(void (^)(SentryScope *))block
{
    SentryScope *scope = [[SentryScope alloc] initWithScope:SentrySDK.currentHub.scope];
    block(scope);
    return [SentrySDK captureException:exception withScope:scope];
}

+ (BuzzSentryId *)captureException:(NSException *)exception withScope:(SentryScope *)scope
{
    return [SentrySDK.currentHub captureException:exception withScope:scope];
}

+ (BuzzSentryId *)captureMessage:(NSString *)message
{
    return [SentrySDK captureMessage:message withScope:SentrySDK.currentHub.scope];
}

+ (BuzzSentryId *)captureMessage:(NSString *)message withScopeBlock:(void (^)(SentryScope *))block
{
    SentryScope *scope = [[SentryScope alloc] initWithScope:SentrySDK.currentHub.scope];
    block(scope);
    return [SentrySDK captureMessage:message withScope:scope];
}

+ (BuzzSentryId *)captureMessage:(NSString *)message withScope:(SentryScope *)scope
{
    return [SentrySDK.currentHub captureMessage:message withScope:scope];
}

/**
 * Needed by hybrid SDKs as react-native to synchronously capture an envelope.
 */
+ (void)captureEnvelope:(BuzzSentryEnvelope *)envelope
{
    [SentrySDK.currentHub captureEnvelope:envelope];
}

/**
 * Needed by hybrid SDKs as react-native to synchronously store an envelope to disk.
 */
+ (void)storeEnvelope:(BuzzSentryEnvelope *)envelope
{
    if (nil != [SentrySDK.currentHub getClient]) {
        [[SentrySDK.currentHub getClient] storeEnvelope:envelope];
    }
}

+ (void)captureUserFeedback:(BuzzSentryUserFeedback *)userFeedback
{
    [SentrySDK.currentHub captureUserFeedback:userFeedback];
}

+ (void)addBreadcrumb:(BuzzSentryBreadcrumb *)crumb
{
    [SentrySDK.currentHub addBreadcrumb:crumb];
}

+ (void)configureScope:(void (^)(SentryScope *scope))callback
{
    [SentrySDK.currentHub configureScope:callback];
}

+ (void)setUser:(BuzzSentryUser *_Nullable)user
{
    [SentrySDK.currentHub setUser:user];
}

+ (BOOL)crashedLastRun
{
    return SentryCrash.sharedInstance.crashedLastLaunch;
}

+ (void)startSession
{
    [SentrySDK.currentHub startSession];
}

+ (void)endSession
{
    [SentrySDK.currentHub endSession];
}

/**
 * Install integrations and keeps ref in `SentryHub.integrations`
 */
+ (void)installIntegrations
{
    if (nil == [SentrySDK.currentHub getClient]) {
        // Gatekeeper
        return;
    }
    BuzzSentryOptions *options = [SentrySDK.currentHub getClient].options;
    for (NSString *integrationName in [SentrySDK.currentHub getClient].options.integrations) {
        Class integrationClass = NSClassFromString(integrationName);
        if (nil == integrationClass) {
            SENTRY_LOG_ERROR(@"[SentryHub doInstallIntegrations] "
                             @"couldn't find \"%@\" -> skipping.",
                integrationName);
            continue;
        } else if ([SentrySDK.currentHub isIntegrationInstalled:integrationClass]) {
            SENTRY_LOG_ERROR(
                @"[SentryHub doInstallIntegrations] already installed \"%@\" -> skipping.",
                integrationName);
            continue;
        }
        id<BuzzSentryIntegrationProtocol> integrationInstance = [[integrationClass alloc] init];
        BOOL shouldInstall = [integrationInstance installWithOptions:options];
        if (shouldInstall) {
            SENTRY_LOG_DEBUG(@"Integration installed: %@", integrationName);
            [SentrySDK.currentHub.installedIntegrations addObject:integrationInstance];
            [SentrySDK.currentHub.installedIntegrationNames addObject:integrationName];
        }
    }
}

+ (void)flush:(NSTimeInterval)timeout
{
    [SentrySDK.currentHub flush:timeout];
}

/**
 * Closes the SDK and uninstalls all the integrations.
 */
+ (void)close
{
    // pop the hub and unset
    SentryHub *hub = SentrySDK.currentHub;
    [SentrySDK setCurrentHub:nil];

    // uninstall all the integrations
    for (NSObject<BuzzSentryIntegrationProtocol> *integration in hub.installedIntegrations) {
        if ([integration respondsToSelector:@selector(uninstall)]) {
            [integration uninstall];
        }
    }
    [hub.installedIntegrations removeAllObjects];

    // close the client
    BuzzSentryClient *client = [hub getClient];
    client.options.enabled = NO;
    [hub bindClient:nil];

    [SentryDependencyContainer reset];

    SENTRY_LOG_DEBUG(@"SDK closed!");
}

#ifndef __clang_analyzer__
// Code not to be analyzed
+ (void)crash
{
    int *p = 0;
    *p = 0;
}
#endif

@end

NS_ASSUME_NONNULL_END
