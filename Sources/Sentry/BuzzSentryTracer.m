#import "BuzzSentryTracer.h"
#import "NSDictionary+BuzzSentrySanitize.h"
#import "PrivateBuzzSentrySDKOnly.h"
#import "BuzzSentryAppStartMeasurement.h"
#import "BuzzSentryClient.h"
#import "BuzzSentryCurrentDate.h"
#import "BuzzSentryFramesTracker.h"
#import "BuzzSentryHub+Private.h"
#import "BuzzSentryLog.h"
#import "BuzzSentryNoOpSpan.h"
#import "SentryProfiler.h"
#import "SentryProfilesSampler.h"
#import "SentryProfilingConditionals.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentryScope.h"
#import "BuzzSentrySpan.h"
#import "BuzzSentrySpanContext.h"
#import "BuzzSentrySpanId.h"
#import "SentryTime.h"
#import "BuzzSentryTraceContext.h"
#import "BuzzSentryTransaction.h"
#import "BuzzSentryTransactionContext.h"
#import "BuzzSentryUIViewControllerPerformanceTracker.h"
#import <BuzzSentryDispatchQueueWrapper.h>
#import <BuzzSentryMeasurementValue.h>
#import <BuzzSentryScreenFrames.h>
#import <BuzzSentrySpanOperations.h>

NS_ASSUME_NONNULL_BEGIN

static const void *spanTimestampObserver = &spanTimestampObserver;

/**
 * The maximum amount of seconds the app start measurement end time and the start time of the
 * transaction are allowed to be apart.
 */
static const NSTimeInterval SENTRY_APP_START_MEASUREMENT_DIFFERENCE = 5.0;
static const NSTimeInterval SENTRY_AUTO_TRANSACTION_MAX_DURATION = 500.0;

@interface
BuzzSentryTracer ()

@property (nonatomic, strong) BuzzSentrySpan *rootSpan;
@property (nonatomic, strong) BuzzSentryHub *hub;
@property (nonatomic) BuzzSentrySpanStatus finishStatus;
/** This property is different from isFinished. While isFinished states if the tracer is actually
 * finished, this property tells you if finish was called on the tracer. Calling finish doesn't
 * necessarily lead to finishing the tracer, because it could still wait for child spans to finish
 * if waitForChildren is <code>YES</code>. */
@property (nonatomic) BOOL wasFinishCalled;
@property (nonatomic) NSTimeInterval idleTimeout;
@property (nonatomic, nullable, strong) BuzzSentryDispatchQueueWrapper *dispatchQueueWrapper;

@end

@implementation BuzzSentryTracer {
    /** Wether the tracer should wait for child spans to finish before finishing itself. */
    BOOL _waitForChildren;
    BuzzSentryTraceContext *_traceContext;
    BuzzSentryAppStartMeasurement *appStartMeasurement;
    NSMutableDictionary<NSString *, id> *_tags;
    NSMutableDictionary<NSString *, id> *_data;
    NSMutableDictionary<NSString *, BuzzSentryMeasurementValue *> *_measurements;
    dispatch_block_t _idleTimeoutBlock;
    NSMutableArray<id<BuzzSentrySpan>> *_children;

#if SENTRY_HAS_UIKIT
    BOOL _startTimeChanged;

    NSUInteger initTotalFrames;
    NSUInteger initSlowFrames;
    NSUInteger initFrozenFrames;
#endif
}

static NSObject *appStartMeasurementLock;
static BOOL appStartMeasurementRead;

+ (void)initialize
{
    if (self == [BuzzSentryTracer class]) {
        appStartMeasurementLock = [[NSObject alloc] init];
        appStartMeasurementRead = NO;
    }
}

- (instancetype)initWithTransactionContext:(BuzzSentryTransactionContext *)transactionContext
                                       hub:(nullable BuzzSentryHub *)hub
{
    return [self initWithTransactionContext:transactionContext
                                        hub:hub
                    profilesSamplerDecision:nil
                            waitForChildren:NO];
}

- (instancetype)initWithTransactionContext:(BuzzSentryTransactionContext *)transactionContext
                                       hub:(nullable BuzzSentryHub *)hub
                           waitForChildren:(BOOL)waitForChildren
{
    return [self initWithTransactionContext:transactionContext
                                        hub:hub
                    profilesSamplerDecision:nil
                            waitForChildren:waitForChildren
                                idleTimeout:0.0
                       dispatchQueueWrapper:nil];
}

- (instancetype)initWithTransactionContext:(BuzzSentryTransactionContext *)transactionContext
                                       hub:(nullable BuzzSentryHub *)hub
                   profilesSamplerDecision:
                       (nullable SentryProfilesSamplerDecision *)profilesSamplerDecision
                           waitForChildren:(BOOL)waitForChildren
{
    return [self initWithTransactionContext:transactionContext
                                        hub:hub
                    profilesSamplerDecision:profilesSamplerDecision
                            waitForChildren:waitForChildren
                                idleTimeout:0.0
                       dispatchQueueWrapper:nil];
}

- (instancetype)initWithTransactionContext:(BuzzSentryTransactionContext *)transactionContext
                                       hub:(nullable BuzzSentryHub *)hub
                   profilesSamplerDecision:
                       (nullable SentryProfilesSamplerDecision *)profilesSamplerDecision
                               idleTimeout:(NSTimeInterval)idleTimeout
                      dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
{
    return [self initWithTransactionContext:transactionContext
                                        hub:hub
                    profilesSamplerDecision:profilesSamplerDecision
                            waitForChildren:YES
                                idleTimeout:idleTimeout
                       dispatchQueueWrapper:dispatchQueueWrapper];
}

- (instancetype)
    initWithTransactionContext:(BuzzSentryTransactionContext *)transactionContext
                           hub:(nullable BuzzSentryHub *)hub
       profilesSamplerDecision:(nullable SentryProfilesSamplerDecision *)profilesSamplerDecision
               waitForChildren:(BOOL)waitForChildren
                   idleTimeout:(NSTimeInterval)idleTimeout
          dispatchQueueWrapper:(nullable BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
{
    if (self = [super init]) {
        self.rootSpan = [[BuzzSentrySpan alloc] initWithTracer:self context:transactionContext];
        self.transactionContext = transactionContext;
        _children = [[NSMutableArray alloc] init];
        self.hub = hub;
        self.wasFinishCalled = NO;
        _waitForChildren = waitForChildren;
        _tags = [[NSMutableDictionary alloc] init];
        _data = [[NSMutableDictionary alloc] init];
        _measurements = [[NSMutableDictionary alloc] init];
        self.finishStatus = kBuzzSentrySpanStatusUndefined;
        self.idleTimeout = idleTimeout;
        self.dispatchQueueWrapper = dispatchQueueWrapper;
        appStartMeasurement = [self getAppStartMeasurement];

        if ([self hasIdleTimeout]) {
            [self dispatchIdleTimeout];
        }

#if SENTRY_HAS_UIKIT
        _startTimeChanged = NO;

        // Store current amount of frames at the beginning to be able to calculate the amount of
        // frames at the end of the transaction.
        BuzzSentryFramesTracker *framesTracker = [BuzzSentryFramesTracker sharedInstance];
        if (framesTracker.isRunning) {
            BuzzSentryScreenFrames *currentFrames = framesTracker.currentFrames;
            initTotalFrames = currentFrames.total;
            initSlowFrames = currentFrames.slow;
            initFrozenFrames = currentFrames.frozen;
        }
#endif // SENTRY_HAS_UIKIT

#if SENTRY_TARGET_PROFILING_SUPPORTED
        if (profilesSamplerDecision.decision == kBuzzSentrySampleDecisionYes) {
            [SentryProfiler startForSpanID:transactionContext.spanId hub:hub];
        }
#endif // SENTRY_TARGET_PROFILING_SUPPORTED
    }

    return self;
}

- (void)dispatchIdleTimeout
{
    if (_idleTimeoutBlock != nil) {
        [self.dispatchQueueWrapper dispatchCancel:_idleTimeoutBlock];
    }
    __block BuzzSentryTracer *_self = self;
    _idleTimeoutBlock = dispatch_block_create(0, ^{ [_self finishInternal]; });
    [self.dispatchQueueWrapper dispatchAfter:self.idleTimeout block:_idleTimeoutBlock];
}

- (BOOL)hasIdleTimeout
{
    return self.idleTimeout > 0 && self.dispatchQueueWrapper != nil;
}

- (BOOL)isAutoGeneratedTransaction
{
    return self.waitForChildren || [self hasIdleTimeout];
}

- (void)cancelIdleTimeout
{
    if ([self hasIdleTimeout]) {
        [self.dispatchQueueWrapper dispatchCancel:_idleTimeoutBlock];
    }
}

- (id<BuzzSentrySpan>)getActiveSpan
{
    id<BuzzSentrySpan> span;

    if (self.delegate) {
        @synchronized(_children) {
            span = [self.delegate activeSpanForTracer:self];
            if (span == nil || span == self || ![_children containsObject:span]) {
                span = _rootSpan;
            }
        }
    } else {
        span = _rootSpan;
    }

    return span;
}

- (id<BuzzSentrySpan>)startChildWithOperation:(NSString *)operation
{
    return [[self getActiveSpan] startChildWithOperation:operation];
}

- (id<BuzzSentrySpan>)startChildWithOperation:(NSString *)operation
                              description:(nullable NSString *)description
{
    return [[self getActiveSpan] startChildWithOperation:operation description:description];
}

- (id<BuzzSentrySpan>)startChildWithParentId:(BuzzSentrySpanId *)parentId
                               operation:(NSString *)operation
                             description:(nullable NSString *)description
{
    [self cancelIdleTimeout];

    if (self.isFinished) {
        SENTRY_LOG_WARN(
            @"Starting a child on a finished span is not supported; it won't be sent to Sentry.");
        return [BuzzSentryNoOpSpan shared];
    }

    BuzzSentrySpanContext *context =
        [[BuzzSentrySpanContext alloc] initWithTraceId:_rootSpan.context.traceId
                                            spanId:[[BuzzSentrySpanId alloc] init]
                                          parentId:parentId
                                         operation:operation
                                           sampled:_rootSpan.context.sampled];
    context.spanDescription = description;

    SENTRY_LOG_DEBUG(@"Starting child span under %@", parentId.BuzzSentrySpanIdString);
    BuzzSentrySpan *child = [[BuzzSentrySpan alloc] initWithTracer:self context:context];
    @synchronized(_children) {
        [_children addObject:child];
    }

    return child;
}

- (void)spanFinished:(id<BuzzSentrySpan>)finishedSpan
{
    // Calling canBeFinished on the rootSpan would end up in an endless loop because canBeFinished
    // calls finish on the rootSpan.
    if (finishedSpan != self.rootSpan) {
        [self canBeFinished];
    }
}

- (BuzzSentrySpanContext *)context
{
    return self.rootSpan.context;
}

- (nullable NSDate *)timestamp
{
    return self.rootSpan.timestamp;
}

- (void)setTimestamp:(nullable NSDate *)timestamp
{
    self.rootSpan.timestamp = timestamp;
}

- (nullable NSDate *)startTimestamp
{
    return self.rootSpan.startTimestamp;
}

- (BuzzSentryTraceContext *)traceContext
{
    if (_traceContext == nil) {
        @synchronized(self) {
            if (_traceContext == nil) {
                _traceContext = [[BuzzSentryTraceContext alloc] initWithTracer:self
                                                                     scope:_hub.scope
                                                                   options:BuzzSentrySDK.options];
            }
        }
    }
    return _traceContext;
}

- (void)setStartTimestamp:(nullable NSDate *)startTimestamp
{
    self.rootSpan.startTimestamp = startTimestamp;

#if SENTRY_HAS_UIKIT
    _startTimeChanged = YES;
#endif
}

- (nullable NSDictionary<NSString *, id> *)data
{
    @synchronized(_data) {
        return [_data copy];
    }
}

- (NSDictionary<NSString *, id> *)tags
{
    @synchronized(_tags) {
        return [_tags copy];
    }
}

- (BOOL)isFinished
{
    return self.rootSpan.isFinished;
}

- (NSArray<id<BuzzSentrySpan>> *)children
{
    return [_children copy];
}

- (void)setDataValue:(nullable id)value forKey:(NSString *)key
{
    @synchronized(_data) {
        [_data setValue:value forKey:key];
    }
}

- (void)setExtraValue:(nullable id)value forKey:(NSString *)key
{
    [self setDataValue:value forKey:key];
}

- (void)removeDataForKey:(NSString *)key
{
    @synchronized(_data) {
        [_data removeObjectForKey:key];
    }
}

- (void)setTagValue:(NSString *)value forKey:(NSString *)key
{
    @synchronized(_tags) {
        [_tags setValue:value forKey:key];
    }
}

- (void)removeTagForKey:(NSString *)key
{
    @synchronized(_tags) {
        [_tags removeObjectForKey:key];
    }
}

- (void)setMeasurement:(NSString *)name value:(NSNumber *)value
{
    BuzzSentryMeasurementValue *measurement = [[BuzzSentryMeasurementValue alloc] initWithValue:value];
    _measurements[name] = measurement;
}

- (void)setMeasurement:(NSString *)name value:(NSNumber *)value unit:(BuzzSentryMeasurementUnit *)unit
{
    BuzzSentryMeasurementValue *measurement = [[BuzzSentryMeasurementValue alloc] initWithValue:value
                                                                                   unit:unit];
    _measurements[name] = measurement;
}

- (BuzzSentryTraceHeader *)toTraceHeader
{
    return [self.rootSpan toTraceHeader];
}

- (void)finish
{
    [self finishWithStatus:kBuzzSentrySpanStatusOk];
}

- (void)finishWithStatus:(BuzzSentrySpanStatus)status
{
    self.wasFinishCalled = YES;
    _finishStatus = status;

    [self cancelIdleTimeout];
    [self canBeFinished];
}

- (void)canBeFinished
{
    // Transaction already finished and captured.
    // Sending another transaction and spans with
    // the same BuzzSentryId would be an error.
    if (self.rootSpan.isFinished)
        return;

    BOOL hasUnfinishedChildSpansToWaitFor = [self hasUnfinishedChildSpansToWaitFor];
    if (!self.wasFinishCalled && !hasUnfinishedChildSpansToWaitFor && [self hasIdleTimeout]) {
        [self dispatchIdleTimeout];
        return;
    }

    if (!self.wasFinishCalled || hasUnfinishedChildSpansToWaitFor)
        return;

    [self finishInternal];
}

- (BOOL)hasUnfinishedChildSpansToWaitFor
{
    if (!_waitForChildren) {
        return NO;
    }

    @synchronized(_children) {
        for (id<BuzzSentrySpan> span in _children) {
            if (![span isFinished])
                return YES;
        }
        return NO;
    }
}

- (void)finishInternal
{
    [_rootSpan finishWithStatus:_finishStatus];

    if (self.finishCallback) {
        self.finishCallback(self);

        // The callback will only be executed once. No need to keep the reference and we avoid
        // potential retain cycles.
        self.finishCallback = nil;
    }

    if (_hub == nil) {
        return;
    }

    [_hub.scope useSpan:^(id<BuzzSentrySpan> _Nullable span) {
        if (span == self) {
            [self->_hub.scope setSpan:nil];
        }
    }];

    @synchronized(_children) {
        if (self.idleTimeout > 0.0 && _children.count == 0) {
            return;
        }

        for (id<BuzzSentrySpan> span in _children) {
            if (!span.isFinished) {
                [span finishWithStatus:kBuzzSentrySpanStatusDeadlineExceeded];

                // Unfinished children should have the same
                // end timestamp as their parent transaction
                span.timestamp = self.timestamp;
            }
        }

        if ([self hasIdleTimeout]) {
            [self trimEndTimestamp];
        }
    }

#if SENTRY_TARGET_PROFILING_SUPPORTED
    [SentryProfiler stopProfilingSpan:self.rootSpan];
#endif // SENTRY_TARGET_PROFILING_SUPPORTED

    BuzzSentryTransaction *transaction = [self toTransaction];

    // Prewarming can execute code up to viewDidLoad of a UIViewController, and keep the app in the
    // background. This can lead to auto-generated transactions lasting for minutes or event hours.
    // Therefore, we drop transactions lasting longer than SENTRY_AUTO_TRANSACTION_MAX_DURATION.
    NSTimeInterval transactionDuration = [self.timestamp timeIntervalSinceDate:self.startTimestamp];
    if ([self isAutoGeneratedTransaction]
        && transactionDuration >= SENTRY_AUTO_TRANSACTION_MAX_DURATION) {
        SENTRY_LOG_INFO(@"Auto generated transaction exceeded the max duration of %f seconds. Not "
                        @"capturing transaction.",
            SENTRY_AUTO_TRANSACTION_MAX_DURATION);
#if SENTRY_TARGET_PROFILING_SUPPORTED
        [SentryProfiler dropTransaction:transaction];
#endif // SENTRY_TARGET_PROFILING_SUPPORTED
        return;
    }

    [_hub captureTransaction:transaction withScope:_hub.scope];

#if SENTRY_TARGET_PROFILING_SUPPORTED
    [SentryProfiler linkTransaction:transaction];
#endif // SENTRY_TARGET_PROFILING_SUPPORTED
}

- (void)trimEndTimestamp
{
    NSDate *oldest = self.startTimestamp;

    for (id<BuzzSentrySpan> childSpan in _children) {
        if ([oldest compare:childSpan.timestamp] == NSOrderedAscending) {
            oldest = childSpan.timestamp;
        }
    }

    if (oldest) {
        self.timestamp = oldest;
    }
}

- (BuzzSentryTransaction *)toTransaction
{
    NSArray<id<BuzzSentrySpan>> *appStartSpans = [self buildAppStartSpans];

    NSArray<id<BuzzSentrySpan>> *spans;
    @synchronized(_children) {
        [_children addObjectsFromArray:appStartSpans];
        spans = [_children copy];
    }

    if (appStartMeasurement != nil) {
        [self setStartTimestamp:appStartMeasurement.appStartTimestamp];
    }

    BuzzSentryTransaction *transaction = [[BuzzSentryTransaction alloc] initWithTrace:self children:spans];
    transaction.transaction = self.transactionContext.name;
    [self addMeasurements:transaction];
    return transaction;
}

- (nullable BuzzSentryAppStartMeasurement *)getAppStartMeasurement
{
    // Only send app start measurement for transactions generated by auto performance
    // instrumentation.
    if (![self.context.operation isEqualToString:BuzzSentrySpanOperationUILoad]) {
        return nil;
    }

    // Hybrid SDKs send the app start measurement themselves.
    if (PrivateBuzzSentrySDKOnly.appStartMeasurementHybridSDKMode) {
        return nil;
    }

    // Double-Checked Locking to avoid acquiring unnecessary locks.
    if (appStartMeasurementRead == YES) {
        return nil;
    }

    BuzzSentryAppStartMeasurement *measurement = nil;
    @synchronized(appStartMeasurementLock) {
        if (appStartMeasurementRead == YES) {
            return nil;
        }

        measurement = [BuzzSentrySDK getAppStartMeasurement];
        if (measurement == nil) {
            return nil;
        }

        appStartMeasurementRead = YES;
    }

    NSDate *appStartTimestamp = measurement.appStartTimestamp;
    NSDate *appStartEndTimestamp =
        [appStartTimestamp dateByAddingTimeInterval:measurement.duration];

    NSTimeInterval difference = [appStartEndTimestamp timeIntervalSinceDate:self.startTimestamp];

    // If the difference between the end of the app start and the beginning of the current
    // transaction is smaller than SENTRY_APP_START_MEASUREMENT_DIFFERENCE. With this we
    // avoid messing up transactions too much.
    if (difference > SENTRY_APP_START_MEASUREMENT_DIFFERENCE
        || difference < -SENTRY_APP_START_MEASUREMENT_DIFFERENCE) {
        return nil;
    }

    return measurement;
}

- (NSArray<BuzzSentrySpan *> *)buildAppStartSpans
{
    if (appStartMeasurement == nil) {
        return @[];
    }

    NSString *operation;
    NSString *type;

    switch (appStartMeasurement.type) {
    case BuzzSentryAppStartTypeCold:
        operation = @"app.start.cold";
        type = @"Cold Start";
        break;
    case BuzzSentryAppStartTypeWarm:
        operation = @"app.start.warm";
        type = @"Warm Start";
        break;
    default:
        return @[];
    }

    NSDate *appStartEndTimestamp = [appStartMeasurement.appStartTimestamp
        dateByAddingTimeInterval:appStartMeasurement.duration];

    BuzzSentrySpan *appStartSpan = [self buildSpan:_rootSpan.context.spanId
                                     operation:operation
                                   description:type];
    [appStartSpan setStartTimestamp:appStartMeasurement.appStartTimestamp];

    BuzzSentrySpan *premainSpan = [self buildSpan:appStartSpan.context.spanId
                                    operation:operation
                                  description:@"Pre Runtime Init"];
    [premainSpan setStartTimestamp:appStartMeasurement.appStartTimestamp];
    [premainSpan setTimestamp:appStartMeasurement.runtimeInitTimestamp];

    BuzzSentrySpan *runtimeInitSpan = [self buildSpan:appStartSpan.context.spanId
                                        operation:operation
                                      description:@"Runtime Init to Pre Main Initializers"];
    [runtimeInitSpan setStartTimestamp:appStartMeasurement.runtimeInitTimestamp];
    [runtimeInitSpan setTimestamp:appStartMeasurement.moduleInitializationTimestamp];

    BuzzSentrySpan *appInitSpan = [self buildSpan:appStartSpan.context.spanId
                                    operation:operation
                                  description:@"UIKit and Application Init"];
    [appInitSpan setStartTimestamp:appStartMeasurement.moduleInitializationTimestamp];
    [appInitSpan setTimestamp:appStartMeasurement.didFinishLaunchingTimestamp];

    BuzzSentrySpan *frameRenderSpan = [self buildSpan:appStartSpan.context.spanId
                                        operation:operation
                                      description:@"Initial Frame Render"];
    [frameRenderSpan setStartTimestamp:appStartMeasurement.didFinishLaunchingTimestamp];
    [frameRenderSpan setTimestamp:appStartEndTimestamp];

    [appStartSpan setTimestamp:appStartEndTimestamp];

    return @[ appStartSpan, premainSpan, runtimeInitSpan, appInitSpan, frameRenderSpan ];
}

- (void)addMeasurements:(BuzzSentryTransaction *)transaction
{
    if (appStartMeasurement != nil && appStartMeasurement.type != BuzzSentryAppStartTypeUnknown) {
        NSString *type = nil;
        if (appStartMeasurement.type == BuzzSentryAppStartTypeCold) {
            type = @"app_start_cold";
        } else if (appStartMeasurement.type == BuzzSentryAppStartTypeWarm) {
            type = @"app_start_warm";
        }

        if (type != nil) {
            [self setMeasurement:type value:@(appStartMeasurement.duration * 1000)];
        }
    }

#if SENTRY_HAS_UIKIT
    // Frames
    BuzzSentryFramesTracker *framesTracker = [BuzzSentryFramesTracker sharedInstance];
    if (framesTracker.isRunning && !_startTimeChanged) {

        BuzzSentryScreenFrames *currentFrames = framesTracker.currentFrames;
        NSInteger totalFrames = currentFrames.total - initTotalFrames;
        NSInteger slowFrames = currentFrames.slow - initSlowFrames;
        NSInteger frozenFrames = currentFrames.frozen - initFrozenFrames;

        BOOL allBiggerThanZero = totalFrames >= 0 && slowFrames >= 0 && frozenFrames >= 0;
        BOOL oneBiggerThanZero = totalFrames > 0 || slowFrames > 0 || frozenFrames > 0;

        if (allBiggerThanZero && oneBiggerThanZero) {
            [self setMeasurement:@"frames_total" value:@(totalFrames)];
            [self setMeasurement:@"frames_slow" value:@(slowFrames)];
            [self setMeasurement:@"frames_frozen" value:@(frozenFrames)];

            SENTRY_LOG_DEBUG(@"Frames for transaction \"%@\" Total:%ld Slow:%ld Frozen:%ld",
                self.context.operation, (long)totalFrames, (long)slowFrames, (long)frozenFrames);
        }
    }
#endif
}

- (id<BuzzSentrySpan>)buildSpan:(BuzzSentrySpanId *)parentId
                  operation:(NSString *)operation
                description:(NSString *)description
{
    BuzzSentrySpanContext *context =
        [[BuzzSentrySpanContext alloc] initWithTraceId:_rootSpan.context.traceId
                                            spanId:[[BuzzSentrySpanId alloc] init]
                                          parentId:parentId
                                         operation:operation
                                           sampled:_rootSpan.context.sampled];
    context.spanDescription = description;

    return [[BuzzSentrySpan alloc] initWithTracer:self context:context];
}

- (NSDictionary *)serialize
{
    NSMutableDictionary<NSString *, id> *mutableDictionary =
        [[NSMutableDictionary alloc] initWithDictionary:[_rootSpan serialize]];

    @synchronized(_data) {
        if (_data.count > 0) {
            NSMutableDictionary *data = _data.mutableCopy;
            if (mutableDictionary[@"data"] != nil &&
                [mutableDictionary[@"data"] isKindOfClass:NSDictionary.class]) {
                [data addEntriesFromDictionary:mutableDictionary[@"data"]];
            }
            mutableDictionary[@"data"] = [data sentry_sanitize];
        }
    }

    @synchronized(_tags) {
        if (_tags.count > 0) {
            NSMutableDictionary *tags = _tags.mutableCopy;
            if (mutableDictionary[@"tags"] != nil &&
                [mutableDictionary[@"tags"] isKindOfClass:NSDictionary.class]) {
                [tags addEntriesFromDictionary:mutableDictionary[@"tags"]];
            }
            mutableDictionary[@"tags"] = tags;
        }
    }

    return mutableDictionary;
}

/**
 * Internal. Only needed for testing.
 */
+ (void)resetAppStartMeasurementRead
{
    @synchronized(appStartMeasurementLock) {
        appStartMeasurementRead = NO;
    }
}

+ (nullable BuzzSentryTracer *)getTracer:(id<BuzzSentrySpan>)span
{
    if (span == nil) {
        return nil;
    }

    if ([span isKindOfClass:[BuzzSentryTracer class]]) {
        return span;
    } else if ([span isKindOfClass:[BuzzSentrySpan class]]) {
        return [(BuzzSentrySpan *)span tracer];
    }
    return nil;
}

@end

NS_ASSUME_NONNULL_END
