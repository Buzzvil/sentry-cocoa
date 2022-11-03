#import "BuzzSentrySDK.h"
#import "PrivateBuzzSentrySDKOnly.h"
#import "BuzzSentryAppStartMeasurement.h"
#import "BuzzSentryBreadcrumb.h"
#import "BuzzSentryClient+Private.h"
#import "SentryCrash.h"
#import "SentryDependencyContainer.h"
#import "BuzzSentryHub+Private.h"
#import "BuzzSentryLog.h"
#import "BuzzSentryMeta.h"
#import "BuzzSentryOptions+Private.h"
#import "BuzzSentryScope.h"

@interface
BuzzSentrySDK ()

@property (class) BuzzSentryHub *currentHub;

@end

NS_ASSUME_NONNULL_BEGIN
@implementation BuzzSentrySDK

static BuzzSentryHub *_Nullable currentHub;
static BOOL crashedLastRunCalled;
static BuzzSentryAppStartMeasurement *BuzzSentrySDKappStartMeasurement;
static NSObject *BuzzSentrySDKappStartMeasurementLock;

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
    if (self == [BuzzSentrySDK class]) {
        BuzzSentrySDKappStartMeasurementLock = [[NSObject alloc] init];
        startInvocations = 0;
    }
}

+ (BuzzSentryHub *)currentHub
{
    @synchronized(self) {
        if (nil == currentHub) {
            currentHub = [[BuzzSentryHub alloc] initWithClient:nil andScope:nil];
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
+ (void)setCurrentHub:(nullable BuzzSentryHub *)hub
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
    @synchronized(BuzzSentrySDKappStartMeasurementLock) {
        BuzzSentrySDKappStartMeasurement = value;
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
    @synchronized(BuzzSentrySDKappStartMeasurementLock) {
        return BuzzSentrySDKappStartMeasurement;
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
        [BuzzSentrySDK startWithOptionsObject:options];
    }
}

+ (void)startWithOptionsObject:(BuzzSentryOptions *)options
{
    startInvocations++;

    [BuzzSentryLog configure:options.debug diagnosticLevel:options.diagnosticLevel];

    BuzzSentryClient *newClient = [[BuzzSentryClient alloc] initWithOptions:options];
    [newClient.fileManager moveAppStateToPreviousAppState];

    // The Hub needs to be initialized with a client so that closing a session
    // can happen.
    [BuzzSentrySDK setCurrentHub:[[BuzzSentryHub alloc] initWithClient:newClient andScope:nil]];
    SENTRY_LOG_DEBUG(@"SDK initialized! Version: %@", BuzzSentryMeta.versionString);
    [BuzzSentrySDK installIntegrations];
}

+ (void)startWithConfigureOptions:(void (^)(BuzzSentryOptions *options))configureOptions
{
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] init];
    configureOptions(options);
    [BuzzSentrySDK startWithOptionsObject:options];
}

+ (void)captureCrashEvent:(BuzzSentryEvent *)event
{
    [BuzzSentrySDK.currentHub captureCrashEvent:event];
}

+ (void)captureCrashEvent:(BuzzSentryEvent *)event withScope:(BuzzSentryScope *)scope
{
    [BuzzSentrySDK.currentHub captureCrashEvent:event withScope:scope];
}

+ (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event
{
    return [BuzzSentrySDK captureEvent:event withScope:BuzzSentrySDK.currentHub.scope];
}

+ (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event withScopeBlock:(void (^)(BuzzSentryScope *))block
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] initWithScope:BuzzSentrySDK.currentHub.scope];
    block(scope);
    return [BuzzSentrySDK captureEvent:event withScope:scope];
}

+ (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event withScope:(BuzzSentryScope *)scope
{
    return [BuzzSentrySDK.currentHub captureEvent:event withScope:scope];
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
    return [BuzzSentrySDK.currentHub startTransactionWithName:name
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
    return [BuzzSentrySDK.currentHub startTransactionWithName:name
                                               nameSource:source
                                                operation:operation
                                              bindToScope:bindToScope];
}

+ (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
{
    return [BuzzSentrySDK.currentHub startTransactionWithContext:transactionContext];
}

+ (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
{
    return [BuzzSentrySDK.currentHub startTransactionWithContext:transactionContext
                                                 bindToScope:bindToScope];
}

+ (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
{
    return [BuzzSentrySDK.currentHub startTransactionWithContext:transactionContext
                                                 bindToScope:bindToScope
                                       customSamplingContext:customSamplingContext];
}

+ (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
{
    return [BuzzSentrySDK.currentHub startTransactionWithContext:transactionContext
                                       customSamplingContext:customSamplingContext];
}

+ (BuzzSentryId *)captureError:(NSError *)error
{
    return [BuzzSentrySDK captureError:error withScope:BuzzSentrySDK.currentHub.scope];
}

+ (BuzzSentryId *)captureError:(NSError *)error withScopeBlock:(void (^)(BuzzSentryScope *_Nonnull))block
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] initWithScope:BuzzSentrySDK.currentHub.scope];
    block(scope);
    return [BuzzSentrySDK captureError:error withScope:scope];
}

+ (BuzzSentryId *)captureError:(NSError *)error withScope:(BuzzSentryScope *)scope
{
    return [BuzzSentrySDK.currentHub captureError:error withScope:scope];
}

+ (BuzzSentryId *)captureException:(NSException *)exception
{
    return [BuzzSentrySDK captureException:exception withScope:BuzzSentrySDK.currentHub.scope];
}

+ (BuzzSentryId *)captureException:(NSException *)exception
                withScopeBlock:(void (^)(BuzzSentryScope *))block
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] initWithScope:BuzzSentrySDK.currentHub.scope];
    block(scope);
    return [BuzzSentrySDK captureException:exception withScope:scope];
}

+ (BuzzSentryId *)captureException:(NSException *)exception withScope:(BuzzSentryScope *)scope
{
    return [BuzzSentrySDK.currentHub captureException:exception withScope:scope];
}

+ (BuzzSentryId *)captureMessage:(NSString *)message
{
    return [BuzzSentrySDK captureMessage:message withScope:BuzzSentrySDK.currentHub.scope];
}

+ (BuzzSentryId *)captureMessage:(NSString *)message withScopeBlock:(void (^)(BuzzSentryScope *))block
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] initWithScope:BuzzSentrySDK.currentHub.scope];
    block(scope);
    return [BuzzSentrySDK captureMessage:message withScope:scope];
}

+ (BuzzSentryId *)captureMessage:(NSString *)message withScope:(BuzzSentryScope *)scope
{
    return [BuzzSentrySDK.currentHub captureMessage:message withScope:scope];
}

/**
 * Needed by hybrid SDKs as react-native to synchronously capture an envelope.
 */
+ (void)captureEnvelope:(BuzzSentryEnvelope *)envelope
{
    [BuzzSentrySDK.currentHub captureEnvelope:envelope];
}

/**
 * Needed by hybrid SDKs as react-native to synchronously store an envelope to disk.
 */
+ (void)storeEnvelope:(BuzzSentryEnvelope *)envelope
{
    if (nil != [BuzzSentrySDK.currentHub getClient]) {
        [[BuzzSentrySDK.currentHub getClient] storeEnvelope:envelope];
    }
}

+ (void)captureUserFeedback:(BuzzSentryUserFeedback *)userFeedback
{
    [BuzzSentrySDK.currentHub captureUserFeedback:userFeedback];
}

+ (void)addBreadcrumb:(BuzzSentryBreadcrumb *)crumb
{
    [BuzzSentrySDK.currentHub addBreadcrumb:crumb];
}

+ (void)configureScope:(void (^)(BuzzSentryScope *scope))callback
{
    [BuzzSentrySDK.currentHub configureScope:callback];
}

+ (void)setUser:(BuzzSentryUser *_Nullable)user
{
    [BuzzSentrySDK.currentHub setUser:user];
}

+ (BOOL)crashedLastRun
{
    return SentryCrash.sharedInstance.crashedLastLaunch;
}

+ (void)startSession
{
    [BuzzSentrySDK.currentHub startSession];
}

+ (void)endSession
{
    [BuzzSentrySDK.currentHub endSession];
}

/**
 * Install integrations and keeps ref in `BuzzSentryHub.integrations`
 */
+ (void)installIntegrations
{
    if (nil == [BuzzSentrySDK.currentHub getClient]) {
        // Gatekeeper
        return;
    }
    BuzzSentryOptions *options = [BuzzSentrySDK.currentHub getClient].options;
    for (NSString *integrationName in [BuzzSentrySDK.currentHub getClient].options.integrations) {
        Class integrationClass = NSClassFromString(integrationName);
        if (nil == integrationClass) {
            SENTRY_LOG_ERROR(@"[BuzzSentryHub doInstallIntegrations] "
                             @"couldn't find \"%@\" -> skipping.",
                integrationName);
            continue;
        } else if ([BuzzSentrySDK.currentHub isIntegrationInstalled:integrationClass]) {
            SENTRY_LOG_ERROR(
                @"[BuzzSentryHub doInstallIntegrations] already installed \"%@\" -> skipping.",
                integrationName);
            continue;
        }
        id<BuzzSentryIntegrationProtocol> integrationInstance = [[integrationClass alloc] init];
        BOOL shouldInstall = [integrationInstance installWithOptions:options];
        if (shouldInstall) {
            SENTRY_LOG_DEBUG(@"Integration installed: %@", integrationName);
            [BuzzSentrySDK.currentHub.installedIntegrations addObject:integrationInstance];
            [BuzzSentrySDK.currentHub.installedIntegrationNames addObject:integrationName];
        }
    }
}

+ (void)flush:(NSTimeInterval)timeout
{
    [BuzzSentrySDK.currentHub flush:timeout];
}

/**
 * Closes the SDK and uninstalls all the integrations.
 */
+ (void)close
{
    // pop the hub and unset
    BuzzSentryHub *hub = BuzzSentrySDK.currentHub;
    [BuzzSentrySDK setCurrentHub:nil];

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
