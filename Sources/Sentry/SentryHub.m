#import "SentryHub.h"
#import "BuzzSentryClient+Private.h"
#import "SentryCrashWrapper.h"
#import "SentryCurrentDateProvider.h"
#import "SentryDefaultCurrentDateProvider.h"
#import "SentryDependencyContainer.h"
#import "BuzzSentryEnvelope.h"
#import "BuzzSentryEnvelopeItemType.h"
#import "BuzzSentryEvent+Private.h"
#import "SentryFileManager.h"
#import "BuzzSentryId.h"
#import "SentryLog.h"
#import "SentryProfilesSampler.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentrySamplingContext.h"
#import "SentryScope.h"
#import "SentrySerialization.h"
#import "BuzzSentryTracer.h"
#import "BuzzSentryTracesSampler.h"
#import "BuzzSentryTransaction.h"
#import "BuzzSentryTransactionContext+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface
SentryHub ()

@property (nullable, nonatomic, strong) BuzzSentryClient *client;
@property (nullable, nonatomic, strong) SentryScope *scope;
@property (nonatomic, strong) SentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) BuzzSentryTracesSampler *tracesSampler;
@property (nonatomic, strong) SentryProfilesSampler *profilesSampler;
@property (nonatomic, strong) id<SentryCurrentDateProvider> currentDateProvider;
@property (nonatomic, strong)
    NSMutableArray<NSObject<BuzzSentryIntegrationProtocol> *> *installedIntegrations;
@property (nonatomic, strong) NSMutableArray<NSString *> *installedIntegrationNames;

@end

@implementation SentryHub {
    NSObject *_sessionLock;
}

- (instancetype)initWithClient:(nullable BuzzSentryClient *)client
                      andScope:(nullable SentryScope *)scope
{
    if (self = [super init]) {
        _client = client;
        _scope = scope;
        _sessionLock = [[NSObject alloc] init];
        _installedIntegrations = [[NSMutableArray alloc] init];
        _installedIntegrationNames = [[NSMutableArray alloc] init];
        _crashWrapper = [SentryCrashWrapper sharedInstance];
        _tracesSampler = [[BuzzSentryTracesSampler alloc] initWithOptions:client.options];
#if SENTRY_TARGET_PROFILING_SUPPORTED
        if (client.options.isProfilingEnabled) {
            _profilesSampler = [[SentryProfilesSampler alloc] initWithOptions:client.options];
        }
#endif
        _currentDateProvider = [SentryDefaultCurrentDateProvider sharedInstance];
    }
    return self;
}

/** Internal constructor for testing */
- (instancetype)initWithClient:(nullable BuzzSentryClient *)client
                      andScope:(nullable SentryScope *)scope
               andCrashWrapper:(SentryCrashWrapper *)crashWrapper
        andCurrentDateProvider:(id<SentryCurrentDateProvider>)currentDateProvider
{
    self = [self initWithClient:client andScope:scope];
    _crashWrapper = crashWrapper;
    _currentDateProvider = currentDateProvider;

    return self;
}

- (void)startSession
{
    BuzzSentrySession *lastSession = nil;
    SentryScope *scope = self.scope;
    BuzzSentryOptions *options = [_client options];
    if (nil == options || nil == options.releaseName) {
        [SentryLog
            logWithMessage:[NSString stringWithFormat:@"No option or release to start a session."]
                  andLevel:kSentryLevelError];
        return;
    }
    @synchronized(_sessionLock) {
        if (nil != _session) {
            lastSession = _session;
        }
        _session = [[BuzzSentrySession alloc] initWithReleaseName:options.releaseName];

        NSString *environment = options.environment;
        if (nil != environment) {
            _session.environment = environment;
        }

        [scope applyToSession:_session];

        [self storeCurrentSession:_session];
        // TODO: Capture outside the lock. Not the reference in the scope.
        [self captureSession:_session];
    }
    [lastSession endSessionExitedWithTimestamp:[self.currentDateProvider date]];
    [self captureSession:lastSession];
}

- (void)endSession
{
    [self endSessionWithTimestamp:[self.currentDateProvider date]];
}

- (void)endSessionWithTimestamp:(NSDate *)timestamp
{
    BuzzSentrySession *currentSession = nil;
    @synchronized(_sessionLock) {
        currentSession = _session;
        _session = nil;
        [self deleteCurrentSession];
    }

    if (nil == currentSession) {
        SENTRY_LOG_DEBUG(@"No session to end with timestamp.");
        return;
    }

    [currentSession endSessionExitedWithTimestamp:timestamp];
    [self captureSession:currentSession];
}

- (void)storeCurrentSession:(BuzzSentrySession *)session
{
    [[_client fileManager] storeCurrentSession:session];
}

- (void)deleteCurrentSession
{
    [[_client fileManager] deleteCurrentSession];
}

- (void)closeCachedSessionWithTimestamp:(nullable NSDate *)timestamp
{
    SentryFileManager *fileManager = [_client fileManager];
    BuzzSentrySession *session = [fileManager readCurrentSession];
    if (nil == session) {
        SENTRY_LOG_DEBUG(@"No cached session to close.");
        return;
    }
    SENTRY_LOG_DEBUG(@"A cached session was found.");

    // Make sure there's a client bound.
    BuzzSentryClient *client = _client;
    if (nil == client) {
        SENTRY_LOG_DEBUG(@"No client bound.");
        return;
    }

    // The crashed session is handled in SentryCrashIntegration. Checkout the comments there to find
    // out more.
    if (!self.crashWrapper.crashedLastLaunch) {
        if (nil == timestamp) {
            SENTRY_LOG_DEBUG(@"No timestamp to close session was provided. Closing as abnormal. "
                             @"Using session's start time %@",
                session.started);
            timestamp = session.started;
            [session endSessionAbnormalWithTimestamp:timestamp];
        } else {
            SENTRY_LOG_DEBUG(@"Closing cached session as exited.");
            [session endSessionExitedWithTimestamp:timestamp];
        }
        [self deleteCurrentSession];
        [client captureSession:session];
    }
}

- (void)captureSession:(nullable BuzzSentrySession *)session
{
    if (nil != session) {
        BuzzSentryClient *client = _client;

        if (client.options.diagnosticLevel == kSentryLevelDebug) {
            NSData *sessionData = [NSJSONSerialization dataWithJSONObject:[session serialize]
                                                                  options:0
                                                                    error:nil];
            NSString *sessionString = [[NSString alloc] initWithData:sessionData
                                                            encoding:NSUTF8StringEncoding];
            [SentryLog
                logWithMessage:[NSString stringWithFormat:@"Capturing session with status: %@",
                                         sessionString]
                      andLevel:kSentryLevelDebug];
        }
        [client captureSession:session];
    }
}

- (nullable BuzzSentrySession *)incrementSessionErrors
{
    BuzzSentrySession *sessionCopy = nil;
    @synchronized(_sessionLock) {
        if (nil != _session) {
            [_session incrementErrors];
            [self storeCurrentSession:_session];
            sessionCopy = [_session copy];
        }
    }

    return sessionCopy;
}

- (void)captureCrashEvent:(BuzzSentryEvent *)event
{
    [self captureCrashEvent:event withScope:self.scope];
}

/**
 * If autoSessionTracking is enabled we want to send the crash and the event together to get proper
 * numbers for release health statistics. If there are multiple crash events to be sent on the start
 * of the SDK there is currently no way to know which one belongs to the crashed session so we just
 * send the session with the first crashed event we receive.
 */
- (void)captureCrashEvent:(BuzzSentryEvent *)event withScope:(SentryScope *)scope
{
    event.isCrashEvent = YES;

    BuzzSentryClient *client = _client;
    if (nil == client) {
        return;
    }

    // Check this condition first to avoid unnecessary I/O
    if (client.options.enableAutoSessionTracking) {
        SentryFileManager *fileManager = [client fileManager];
        BuzzSentrySession *crashedSession = [fileManager readCrashedSession];

        // It can be that there is no session yet, because autoSessionTracking was just enabled and
        // there is a previous crash on disk. In this case we just send the crash event.
        if (nil != crashedSession) {
            [client captureCrashEvent:event withSession:crashedSession withScope:scope];
            [fileManager deleteCrashedSession];
            return;
        }
    }

    [client captureCrashEvent:event withScope:scope];
}

- (BuzzSentryId *)captureTransaction:(BuzzSentryTransaction *)transaction withScope:(SentryScope *)scope
{
    return [self captureTransaction:transaction withScope:scope additionalEnvelopeItems:@[]];
}

- (BuzzSentryId *)captureTransaction:(BuzzSentryTransaction *)transaction
                       withScope:(SentryScope *)scope
         additionalEnvelopeItems:(NSArray<BuzzSentryEnvelopeItem *> *)additionalEnvelopeItems
{
    BuzzSentrySampleDecision decision = transaction.trace.context.sampled;
    if (decision != kBuzzSentrySampleDecisionYes) {
        [self.client recordLostEvent:kBuzzSentryDataCategoryTransaction
                              reason:kBuzzSentryDiscardReasonSampleRate];
        return BuzzSentryId.empty;
    }

    return [self captureEvent:transaction
                      withScope:scope
        additionalEnvelopeItems:additionalEnvelopeItems];
}

- (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event
{
    return [self captureEvent:event withScope:self.scope];
}

- (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event withScope:(SentryScope *)scope
{
    return [self captureEvent:event withScope:scope additionalEnvelopeItems:@[]];
}

- (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event
                  withScope:(SentryScope *)scope
    additionalEnvelopeItems:(NSArray<BuzzSentryEnvelopeItem *> *)additionalEnvelopeItems
{
    BuzzSentryClient *client = _client;
    if (nil != client) {
        return [client captureEvent:event
                          withScope:scope
            additionalEnvelopeItems:additionalEnvelopeItems];
    }
    return BuzzSentryId.empty;
}

- (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name operation:(NSString *)operation
{
    return [self startTransactionWithContext:[[BuzzSentryTransactionContext alloc]
                                                 initWithName:name
                                                   nameSource:kBuzzSentryTransactionNameSourceCustom
                                                    operation:operation]];
}

- (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
                                nameSource:(BuzzSentryTransactionNameSource)source
                                 operation:(NSString *)operation
{
    return [self
        startTransactionWithContext:[[BuzzSentryTransactionContext alloc] initWithName:name
                                                                        nameSource:source
                                                                         operation:operation]];
}

- (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
                                 operation:(NSString *)operation
                               bindToScope:(BOOL)bindToScope
{
    return [self startTransactionWithContext:[[BuzzSentryTransactionContext alloc]
                                                 initWithName:name
                                                   nameSource:kBuzzSentryTransactionNameSourceCustom
                                                    operation:operation]
                                 bindToScope:bindToScope];
}

- (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
                                nameSource:(BuzzSentryTransactionNameSource)source
                                 operation:(NSString *)operation
                               bindToScope:(BOOL)bindToScope
{
    return
        [self startTransactionWithContext:[[BuzzSentryTransactionContext alloc] initWithName:name
                                                                              nameSource:source
                                                                               operation:operation]
                              bindToScope:bindToScope];
}

- (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
{
    return [self startTransactionWithContext:transactionContext customSamplingContext:@{}];
}

- (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
{
    return [self startTransactionWithContext:transactionContext
                                 bindToScope:bindToScope
                       customSamplingContext:@{}];
}

- (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
{
    return [self startTransactionWithContext:transactionContext
                                 bindToScope:false
                       customSamplingContext:customSamplingContext];
}

- (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
{
    return [self startTransactionWithContext:transactionContext
                                 bindToScope:bindToScope
                             waitForChildren:NO
                       customSamplingContext:customSamplingContext];
}

- (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
                              waitForChildren:(BOOL)waitForChildren
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
{
    BuzzSentrySamplingContext *samplingContext =
        [[BuzzSentrySamplingContext alloc] initWithTransactionContext:transactionContext
                                            customSamplingContext:customSamplingContext];

    BuzzSentryTracesSamplerDecision *samplerDecision = [_tracesSampler sample:samplingContext];
    transactionContext.sampled = samplerDecision.decision;
    transactionContext.sampleRate = samplerDecision.sampleRate;

    SentryProfilesSamplerDecision *profilesSamplerDecision =
        [_profilesSampler sample:samplingContext tracesSamplerDecision:samplerDecision];

    id<BuzzSentrySpan> tracer = [[BuzzSentryTracer alloc] initWithTransactionContext:transactionContext
                                                                         hub:self
                                                     profilesSamplerDecision:profilesSamplerDecision
                                                             waitForChildren:waitForChildren];

    if (bindToScope)
        self.scope.span = tracer;

    return tracer;
}

- (BuzzSentryTracer *)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
                                  idleTimeout:(NSTimeInterval)idleTimeout
                         dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
{
    BuzzSentrySamplingContext *samplingContext =
        [[BuzzSentrySamplingContext alloc] initWithTransactionContext:transactionContext
                                            customSamplingContext:customSamplingContext];

    BuzzSentryTracesSamplerDecision *samplerDecision = [_tracesSampler sample:samplingContext];
    transactionContext.sampled = samplerDecision.decision;
    transactionContext.sampleRate = samplerDecision.sampleRate;

    SentryProfilesSamplerDecision *profilesSamplerDecision =
        [_profilesSampler sample:samplingContext tracesSamplerDecision:samplerDecision];

    BuzzSentryTracer *tracer = [[BuzzSentryTracer alloc] initWithTransactionContext:transactionContext
                                                                        hub:self
                                                    profilesSamplerDecision:profilesSamplerDecision
                                                                idleTimeout:idleTimeout
                                                       dispatchQueueWrapper:dispatchQueueWrapper];
    if (bindToScope)
        self.scope.span = tracer;

    return tracer;
}

- (BuzzSentryId *)captureMessage:(NSString *)message
{
    return [self captureMessage:message withScope:self.scope];
}

- (BuzzSentryId *)captureMessage:(NSString *)message withScope:(SentryScope *)scope
{
    BuzzSentryClient *client = _client;
    if (nil != client) {
        return [client captureMessage:message withScope:scope];
    }
    return BuzzSentryId.empty;
}

- (BuzzSentryId *)captureError:(NSError *)error
{
    return [self captureError:error withScope:self.scope];
}

- (BuzzSentryId *)captureError:(NSError *)error withScope:(SentryScope *)scope
{
    BuzzSentrySession *currentSession = [self incrementSessionErrors];
    BuzzSentryClient *client = _client;
    if (nil != client) {
        if (nil != currentSession) {
            return [client captureError:error withSession:currentSession withScope:scope];
        } else {
            return [client captureError:error withScope:scope];
        }
    }
    return BuzzSentryId.empty;
}

- (BuzzSentryId *)captureException:(NSException *)exception
{
    return [self captureException:exception withScope:self.scope];
}

- (BuzzSentryId *)captureException:(NSException *)exception withScope:(SentryScope *)scope
{
    BuzzSentrySession *currentSession = [self incrementSessionErrors];

    BuzzSentryClient *client = _client;
    if (nil != client) {
        if (nil != currentSession) {
            return [client captureException:exception withSession:currentSession withScope:scope];
        } else {
            return [client captureException:exception withScope:scope];
        }
    }
    return BuzzSentryId.empty;
}

- (void)captureUserFeedback:(BuzzSentryUserFeedback *)userFeedback
{
    BuzzSentryClient *client = _client;
    if (nil != client) {
        [client captureUserFeedback:userFeedback];
    }
}

- (void)addBreadcrumb:(BuzzSentryBreadcrumb *)crumb
{
    BuzzSentryOptions *options = [[self client] options];
    if (options.maxBreadcrumbs < 1) {
        return;
    }
    SentryBeforeBreadcrumbCallback callback = [options beforeBreadcrumb];
    if (nil != callback) {
        crumb = callback(crumb);
    }
    if (nil == crumb) {
        SENTRY_LOG_DEBUG(@"Discarded Breadcrumb in `beforeBreadcrumb`");
        return;
    }
    [self.scope addBreadcrumb:crumb];
}

- (nullable BuzzSentryClient *)getClient
{
    return _client;
}

- (void)bindClient:(nullable BuzzSentryClient *)client
{
    self.client = client;
}

- (SentryScope *)scope
{
    @synchronized(self) {
        if (_scope == nil) {
            BuzzSentryClient *client = _client;
            if (nil != client) {
                _scope = [[SentryScope alloc] initWithMaxBreadcrumbs:client.options.maxBreadcrumbs];
            } else {
                _scope = [[SentryScope alloc] init];
            }
        }
        return _scope;
    }
}

- (void)configureScope:(void (^)(SentryScope *scope))callback
{
    SentryScope *scope = self.scope;
    BuzzSentryClient *client = _client;
    if (nil != client && nil != scope) {
        callback(scope);
    }
}

/**
 * Checks if a specific Integration (`integrationClass`) has been installed.
 * @return BOOL If instance of `integrationClass` exists within
 * `SentryHub.installedIntegrations`.
 */
- (BOOL)isIntegrationInstalled:(Class)integrationClass
{
    for (id<BuzzSentryIntegrationProtocol> item in self.installedIntegrations) {
        if ([item isKindOfClass:integrationClass]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)hasIntegration:(NSString *)integrationName
{
    return [self.installedIntegrationNames containsObject:integrationName];
}

- (void)setUser:(nullable BuzzSentryUser *)user
{
    SentryScope *scope = self.scope;
    if (nil != scope) {
        [scope setUser:user];
    }
}

- (void)captureEnvelope:(BuzzSentryEnvelope *)envelope
{
    BuzzSentryClient *client = _client;
    if (nil == client) {
        return;
    }

    [client captureEnvelope:[self updateSessionState:envelope]];
}

- (BuzzSentryEnvelope *)updateSessionState:(BuzzSentryEnvelope *)envelope
{
    if ([self envelopeContainsEventWithErrorOrHigher:envelope.items]) {
        BuzzSentrySession *currentSession = [self incrementSessionErrors];

        if (nil != currentSession) {
            // Create a new envelope with the session update
            NSMutableArray<BuzzSentryEnvelopeItem *> *itemsToSend =
                [[NSMutableArray alloc] initWithArray:envelope.items];
            [itemsToSend addObject:[[BuzzSentryEnvelopeItem alloc] initWithSession:currentSession]];

            return [[BuzzSentryEnvelope alloc] initWithHeader:envelope.header items:itemsToSend];
        }
    }

    return envelope;
}

- (BOOL)envelopeContainsEventWithErrorOrHigher:(NSArray<BuzzSentryEnvelopeItem *> *)items
{
    for (BuzzSentryEnvelopeItem *item in items) {
        if ([item.header.type isEqualToString:BuzzSentryEnvelopeItemTypeEvent]) {
            // If there is no level the default is error
            SentryLevel level = [SentrySerialization levelFromData:item.data];
            if (level >= kSentryLevelError) {
                return YES;
            }
        }
    }

    return NO;
}

- (void)flush:(NSTimeInterval)timeout
{
    BuzzSentryClient *client = _client;
    if (nil != client) {
        [client flush:timeout];
    }
}

@end

NS_ASSUME_NONNULL_END
