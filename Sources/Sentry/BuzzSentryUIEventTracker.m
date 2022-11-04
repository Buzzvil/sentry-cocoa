#import "BuzzSentrySwizzleWrapper.h"
#import <BuzzSentryHub+Private.h>
#import <BuzzSentryLog.h>
#import <BuzzSentrySDK+Private.h>
#import <BuzzSentrySDK.h>
#import <BuzzSentryScope.h>
#import <BuzzSentrySpanOperations.h>
#import <BuzzSentrySpanProtocol.h>
#import <BuzzSentryTracer.h>
#import <BuzzSentryTransactionContext+Private.h>
#import <BuzzSentryUIEventTracker.h>

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const BuzzSentryUIEventTrackerSwizzleSendAction
    = @"BuzzSentryUIEventTrackerSwizzleSendAction";

@interface
BuzzSentryUIEventTracker ()

@property (nonatomic, strong) BuzzSentrySwizzleWrapper *swizzleWrapper;
@property (nonatomic, strong) BuzzSentryDispatchQueueWrapper *dispatchQueueWrapper;
@property (nonatomic, assign) NSTimeInterval idleTimeout;
@property (nullable, nonatomic, strong) NSMutableArray<BuzzSentryTracer *> *activeTransactions;

@end

#endif

@implementation BuzzSentryUIEventTracker

#if SENTRY_HAS_UIKIT

- (instancetype)initWithSwizzleWrapper:(BuzzSentrySwizzleWrapper *)swizzleWrapper
                  dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
                           idleTimeout:(NSTimeInterval)idleTimeout
{
    if (self = [super init]) {
        self.swizzleWrapper = swizzleWrapper;
        self.dispatchQueueWrapper = dispatchQueueWrapper;
        self.idleTimeout = idleTimeout;
        self.activeTransactions = [NSMutableArray new];
    }
    return self;
}

- (void)start
{
    [self.swizzleWrapper
        swizzleSendAction:^(NSString *action, id target, id sender, UIEvent *event) {
            if (target == nil || sender == nil) {
                return;
            }

            // When using an application delegate with SwiftUI we receive touch events here, but
            // the target class name looks something like
            // _TtC7SwiftUIP33_64A26C7A8406856A733B1A7B593971F711Coordinator.primaryActionTriggered,
            // which is unacceptable for a transaction name. Ideally, we should somehow shorten
            // the long name.

            NSString *targetClass = NSStringFromClass([target class]);
            if ([targetClass containsString:@"SwiftUI"]) {
                return;
            }

            NSString *transactionName = [self getTransactionName:action target:targetClass];

            // There might be more active transactions stored, but only the last one might still be
            // active with a timeout. The others are already waiting for their children to finish
            // without a timeout.
            BuzzSentryTracer *currentActiveTransaction;
            @synchronized(self.activeTransactions) {
                currentActiveTransaction = self.activeTransactions.lastObject;
            }

            BOOL sameAction =
                [currentActiveTransaction.transactionContext.name isEqualToString:transactionName];
            if (sameAction) {
                [currentActiveTransaction dispatchIdleTimeout];
                return;
            }

            [currentActiveTransaction finish];

            if (currentActiveTransaction) {
                [BuzzSentryLog
                    logWithMessage:
                        [NSString stringWithFormat:@"BuzzSentryUIEventTracker finished transaction %@",
                                  currentActiveTransaction.transactionContext.name]
                          andLevel:kBuzzSentryLevelDebug];
            }

            NSString *operation = [self getOperation:sender];

            BuzzSentryTransactionContext *context =
                [[BuzzSentryTransactionContext alloc] initWithName:transactionName
                                                    nameSource:kBuzzSentryTransactionNameSourceComponent
                                                     operation:operation];

            __block BuzzSentryTracer *transaction;
            [BuzzSentrySDK.currentHub.scope useSpan:^(id<BuzzSentrySpan> _Nullable span) {
                BOOL ongoingScreenLoadTransaction = span != nil &&
                    [span.context.operation isEqualToString:BuzzSentrySpanOperationUILoad];
                BOOL ongoingManualTransaction = span != nil
                    && ![span.context.operation isEqualToString:BuzzSentrySpanOperationUILoad]
                    && ![span.context.operation containsString:BuzzSentrySpanOperationUIAction];

                BOOL bindToScope = !ongoingScreenLoadTransaction && !ongoingManualTransaction;
                transaction =
                    [BuzzSentrySDK.currentHub startTransactionWithContext:context
                                                          bindToScope:bindToScope
                                                customSamplingContext:@{}
                                                          idleTimeout:self.idleTimeout
                                                 dispatchQueueWrapper:self.dispatchQueueWrapper];

                [BuzzSentryLog
                    logWithMessage:[NSString stringWithFormat:@"BuzzSentryUIEventTracker automatically "
                                                              @"started a new transaction with "
                                                              @"name: %@, bindToScope: %@",
                                             transactionName, bindToScope ? @"YES" : @"NO"]
                          andLevel:kBuzzSentryLevelDebug];
            }];

            if ([[sender class] isSubclassOfClass:[UIView class]]) {
                UIView *view = sender;
                if (view.accessibilityIdentifier) {
                    [transaction setTagValue:view.accessibilityIdentifier
                                      forKey:@"accessibilityIdentifier"];
                }
            }

            transaction.finishCallback = ^(BuzzSentryTracer *tracer) {
                @synchronized(self.activeTransactions) {
                    [self.activeTransactions removeObject:tracer];
                }
            };
            @synchronized(self.activeTransactions) {
                [self.activeTransactions addObject:transaction];
            }
        }
                   forKey:BuzzSentryUIEventTrackerSwizzleSendAction];
}

- (void)stop
{
    [self.swizzleWrapper removeSwizzleSendActionForKey:BuzzSentryUIEventTrackerSwizzleSendAction];
}

- (NSString *)getOperation:(id)sender
{
    Class senderClass = [sender class];
    if ([senderClass isSubclassOfClass:[UIButton class]] ||
        [senderClass isSubclassOfClass:[UIBarButtonItem class]] ||
        [senderClass isSubclassOfClass:[UISegmentedControl class]] ||
        [senderClass isSubclassOfClass:[UIPageControl class]]) {
        return BuzzSentrySpanOperationUIActionClick;
    }

    return BuzzSentrySpanOperationUIAction;
}

/**
 * The action is an Objective-C selector and might look weird for Swift developers. Therefore we
 * convert the selector to a Swift appropriate format aligned with the Swift #selector syntax.
 * method:first:second:third: gets converted to method(first:second:third:)
 */
- (NSString *)getTransactionName:(NSString *)action target:(NSString *)target
{
    NSArray<NSString *> *componens = [action componentsSeparatedByString:@":"];
    if (componens.count > 2) {
        NSMutableString *result =
            [[NSMutableString alloc] initWithFormat:@"%@.%@(", target, componens.firstObject];

        for (int i = 1; i < (componens.count - 1); i++) {
            [result appendFormat:@"%@:", componens[i]];
        }

        [result appendFormat:@")"];

        return result;
    }

    return [NSString stringWithFormat:@"%@.%@", target, componens.firstObject];
}

NS_ASSUME_NONNULL_END

#endif

NS_ASSUME_NONNULL_BEGIN

+ (BOOL)isUIEventOperation:(NSString *)operation
{
    if ([operation isEqualToString:BuzzSentrySpanOperationUIAction]) {
        return YES;
    }
    if ([operation isEqualToString:BuzzSentrySpanOperationUIActionClick]) {
        return YES;
    }
    return NO;
}

@end

NS_ASSUME_NONNULL_END
