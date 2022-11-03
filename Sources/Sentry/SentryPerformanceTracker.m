#import "SentryPerformanceTracker.h"
#import "SentryHub+Private.h"
#import "SentryLog.h"
#import "BuzzSentrySDK+Private.h"
#import "SentryScope.h"
#import "BuzzSentrySpan.h"
#import "BuzzSentrySpanId.h"
#import "BuzzSentrySpanProtocol.h"
#import "BuzzSentryTracer.h"
#import "BuzzSentryTransactionContext+Private.h"
#import "SentryUIEventTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface
SentryPerformanceTracker () <BuzzSentryTracerDelegate>

@property (nonatomic, strong) NSMutableDictionary<BuzzSentrySpanId *, id<BuzzSentrySpan>> *spans;
@property (nonatomic, strong) NSMutableArray<id<BuzzSentrySpan>> *activeSpanStack;

@end

@implementation SentryPerformanceTracker

+ (instancetype)shared
{
    static SentryPerformanceTracker *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.spans = [[NSMutableDictionary alloc] init];
        self.activeSpanStack = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BuzzSentrySpanId *)startSpanWithName:(NSString *)name operation:(NSString *)operation
{
    return [self startSpanWithName:name
                        nameSource:kBuzzSentryTransactionNameSourceCustom
                         operation:operation];
}

- (BuzzSentrySpanId *)startSpanWithName:(NSString *)name
                         nameSource:(BuzzSentryTransactionNameSource)source
                          operation:(NSString *)operation
{
    id<BuzzSentrySpan> activeSpan;
    @synchronized(self.activeSpanStack) {
        activeSpan = [self.activeSpanStack lastObject];
    }

    __block id<BuzzSentrySpan> newSpan;
    if (activeSpan != nil) {
        newSpan = [activeSpan startChildWithOperation:operation description:name];
    } else {
        BuzzSentryTransactionContext *context =
            [[BuzzSentryTransactionContext alloc] initWithName:name
                                                nameSource:source
                                                 operation:operation];

        [SentrySDK.currentHub.scope useSpan:^(id<BuzzSentrySpan> span) {
            BOOL bindToScope = true;
            if (span != nil) {
                if ([SentryUIEventTracker isUIEventOperation:span.context.operation]) {
                    [span finishWithStatus:kBuzzSentrySpanStatusCancelled];
                } else {
                    bindToScope = false;
                }
            }

            newSpan = [SentrySDK.currentHub startTransactionWithContext:context
                                                            bindToScope:bindToScope
                                                        waitForChildren:YES
                                                  customSamplingContext:@ {}];

            if ([newSpan isKindOfClass:[BuzzSentryTracer class]]) {
                [(BuzzSentryTracer *)newSpan setDelegate:self];
            }
        }];
    }

    BuzzSentrySpanId *spanId = newSpan.context.spanId;

    if (spanId != nil) {
        @synchronized(self.spans) {
            self.spans[spanId] = newSpan;
        }
    } else {
        SENTRY_LOG_ERROR(@"startSpanWithName:operation: spanId is nil.");
        return [BuzzSentrySpanId empty];
    }

    return spanId;
}

- (void)measureSpanWithDescription:(NSString *)description
                         operation:(NSString *)operation
                           inBlock:(void (^)(void))block
{
    [self measureSpanWithDescription:description
                          nameSource:kBuzzSentryTransactionNameSourceCustom
                           operation:operation
                             inBlock:block];
}

- (void)measureSpanWithDescription:(NSString *)description
                        nameSource:(BuzzSentryTransactionNameSource)source
                         operation:(NSString *)operation
                           inBlock:(void (^)(void))block
{
    BuzzSentrySpanId *spanId = [self startSpanWithName:description
                                        nameSource:source
                                         operation:operation];
    [self pushActiveSpan:spanId];
    block();
    [self popActiveSpan];
    [self finishSpan:spanId];
}

- (void)measureSpanWithDescription:(NSString *)description
                         operation:(NSString *)operation
                      parentSpanId:(BuzzSentrySpanId *)parentSpanId
                           inBlock:(void (^)(void))block
{
    [self measureSpanWithDescription:description
                          nameSource:kBuzzSentryTransactionNameSourceCustom
                           operation:operation
                        parentSpanId:parentSpanId
                             inBlock:block];
}

- (void)measureSpanWithDescription:(NSString *)description
                        nameSource:(BuzzSentryTransactionNameSource)source
                         operation:(NSString *)operation
                      parentSpanId:(BuzzSentrySpanId *)parentSpanId
                           inBlock:(void (^)(void))block
{
    [self activateSpan:parentSpanId
           duringBlock:^{
               [self measureSpanWithDescription:description
                                     nameSource:source
                                      operation:operation
                                        inBlock:block];
           }];
}

- (void)activateSpan:(BuzzSentrySpanId *)spanId duringBlock:(void (^)(void))block
{

    if ([self pushActiveSpan:spanId]) {
        block();
        [self popActiveSpan];
    } else {
        block();
    }
}

- (nullable BuzzSentrySpanId *)activeSpanId
{
    @synchronized(self.activeSpanStack) {
        return [self.activeSpanStack lastObject].context.spanId;
    }
}

- (BOOL)pushActiveSpan:(BuzzSentrySpanId *)spanId
{
    id<BuzzSentrySpan> toActiveSpan;
    @synchronized(self.spans) {
        toActiveSpan = self.spans[spanId];
    }

    if (toActiveSpan == nil) {
        return NO;
    }

    @synchronized(self.activeSpanStack) {
        [self.activeSpanStack addObject:toActiveSpan];
    }
    return YES;
}

- (void)popActiveSpan
{
    @synchronized(self.activeSpanStack) {
        [self.activeSpanStack removeLastObject];
    }
}

- (void)finishSpan:(BuzzSentrySpanId *)spanId
{
    [self finishSpan:spanId withStatus:kBuzzSentrySpanStatusOk];
}

- (void)finishSpan:(BuzzSentrySpanId *)spanId withStatus:(BuzzSentrySpanStatus)status
{
    id<BuzzSentrySpan> spanTracker;
    @synchronized(self.spans) {
        spanTracker = self.spans[spanId];
        [self.spans removeObjectForKey:spanId];
    }

    [spanTracker finishWithStatus:status];
}

- (BOOL)isSpanAlive:(BuzzSentrySpanId *)spanId
{
    @synchronized(self.spans) {
        return self.spans[spanId] != nil;
    }
}

- (nullable id<BuzzSentrySpan>)getSpan:(BuzzSentrySpanId *)spanId
{
    @synchronized(self.spans) {
        return self.spans[spanId];
    }
}

- (nullable id<BuzzSentrySpan>)activeSpanForTracer:(BuzzSentryTracer *)tracer
{
    @synchronized(self.activeSpanStack) {
        return [self.activeSpanStack lastObject];
    }
}

@end

NS_ASSUME_NONNULL_END
