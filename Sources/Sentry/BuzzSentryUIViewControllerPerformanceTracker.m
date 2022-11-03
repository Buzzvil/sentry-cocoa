#import "BuzzSentryUIViewControllerPerformanceTracker.h"
#import "BuzzSentryHub.h"
#import "SentryLog.h"
#import "BuzzSentryPerformanceTracker+Private.h"
#import "BuzzSentryPerformanceTracker.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentryScope.h"
#import "BuzzSentrySpanId.h"
#import "BuzzSentryUIViewControllerSanitizer.h"
#import <SentryInAppLogic.h>
#import <BuzzSentrySpanOperations.h>
#import <objc/runtime.h>

@interface
BuzzSentryUIViewControllerPerformanceTracker ()

@property (nonatomic, strong) BuzzSentryPerformanceTracker *tracker;
@property (nonatomic, strong) SentryInAppLogic *inAppLogic;

@end

@implementation BuzzSentryUIViewControllerPerformanceTracker

+ (instancetype)shared
{
    static BuzzSentryUIViewControllerPerformanceTracker *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.tracker = BuzzSentryPerformanceTracker.shared;

        BuzzSentryOptions *options = [SentrySDK options];

        self.inAppLogic = [[SentryInAppLogic alloc] initWithInAppIncludes:options.inAppIncludes
                                                            inAppExcludes:options.inAppExcludes];
    }
    return self;
}

#if SENTRY_HAS_UIKIT

- (void)viewControllerLoadView:(UIViewController *)controller
              callbackToOrigin:(void (^)(void))callbackToOrigin
{
    // Since this will be executed for every ViewController,
    // we should not create transactions for classes that should no be swizzled.
    if (![self.inAppLogic isClassInApp:[controller class]]) {
        callbackToOrigin();
        return;
    }

    [self limitOverride:@"loadView"
                  target:controller
        callbackToOrigin:callbackToOrigin
                   block:^{
                       [self createTransaction:controller];

                       [self measurePerformance:@"loadView"
                                         target:controller
                               callbackToOrigin:callbackToOrigin];
                   }];
}

- (void)viewControllerViewDidLoad:(UIViewController *)controller
                 callbackToOrigin:(void (^)(void))callbackToOrigin
{
    [self limitOverride:@"viewDidLoad"
                  target:controller
        callbackToOrigin:callbackToOrigin
                   block:^{
                       [self createTransaction:controller];

                       [self measurePerformance:@"viewDidLoad"
                                         target:controller
                               callbackToOrigin:callbackToOrigin];
                   }];
}

- (void)createTransaction:(UIViewController *)controller
{
    BuzzSentrySpanId *spanId
        = objc_getAssociatedObject(controller, &SENTRY_UI_PERFORMANCE_TRACKER_SPAN_ID);

    // If the user manually calls loadView outside the lifecycle we don't start a new transaction
    // and override the previous id stored.
    if (spanId == nil) {
        NSString *name = [BuzzSentryUIViewControllerSanitizer sanitizeViewControllerName:controller];
        spanId = [self.tracker startSpanWithName:name
                                      nameSource:kBuzzSentryTransactionNameSourceComponent
                                       operation:BuzzSentrySpanOperationUILoad];

        // Use the target itself to store the spanId to avoid using a global mapper.
        objc_setAssociatedObject(controller, &SENTRY_UI_PERFORMANCE_TRACKER_SPAN_ID, spanId,
            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)viewControllerViewWillAppear:(UIViewController *)controller
                    callbackToOrigin:(void (^)(void))callbackToOrigin
{
    void (^limitOverrideBlock)(void) = ^{
        BuzzSentrySpanId *spanId
            = objc_getAssociatedObject(controller, &SENTRY_UI_PERFORMANCE_TRACKER_SPAN_ID);

        if (spanId == nil || ![self.tracker isSpanAlive:spanId]) {
            // We are no longer tracking this UIViewController, just call the base
            // method.
            callbackToOrigin();
            return;
        }

        void (^duringBlock)(void) = ^{
            [self.tracker measureSpanWithDescription:@"viewWillAppear"
                                          nameSource:kBuzzSentryTransactionNameSourceComponent
                                           operation:BuzzSentrySpanOperationUILoad
                                             inBlock:callbackToOrigin];

            BuzzSentrySpanId *viewAppearingId =
                [self.tracker startSpanWithName:@"viewAppearing"
                                     nameSource:kBuzzSentryTransactionNameSourceComponent
                                      operation:BuzzSentrySpanOperationUILoad];

            objc_setAssociatedObject(controller,
                &SENTRY_UI_PERFORMANCE_TRACKER_VIEWAPPEARING_SPAN_ID, viewAppearingId,
                OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        };

        [self.tracker activateSpan:spanId duringBlock:duringBlock];
    };

    [self limitOverride:@"viewWillAppear"
                  target:controller
        callbackToOrigin:callbackToOrigin
                   block:limitOverrideBlock];
}

- (void)viewControllerViewDidAppear:(UIViewController *)controller
                   callbackToOrigin:(void (^)(void))callbackToOrigin
{
    [self finishTransaction:controller
                     status:kBuzzSentrySpanStatusOk
            lifecycleMethod:@"viewDidAppear"
           callbackToOrigin:callbackToOrigin];
}

/**
 * According to the apple docs, see
 * https://developer.apple.com/documentation/uikit/uiviewcontroller: Not all ‘will’ callback methods
 * are paired with only a ‘did’ callback method. You need to ensure that if you start a process in a
 * ‘will’ callback method, you end the process in both the corresponding ‘did’ and the opposite
 * ‘will’ callback method.
 *
 * As stated above viewWillAppear doesn't need to be followed by a viewDidAppear. A viewWillAppear
 * can also be followed by a viewWillDisappear. Therefore, we finish the transaction in
 * viewWillDisappear, if it wasn't already finished in viewDidAppear.
 */
- (void)viewControllerViewWillDisappear:(UIViewController *)controller
                       callbackToOrigin:(void (^)(void))callbackToOrigin
{
    [self finishTransaction:controller
                     status:kBuzzSentrySpanStatusCancelled
            lifecycleMethod:@"viewWillDisappear"
           callbackToOrigin:callbackToOrigin];
}

- (void)finishTransaction:(UIViewController *)controller
                   status:(BuzzSentrySpanStatus)status
          lifecycleMethod:(NSString *)lifecycleMethod
         callbackToOrigin:(void (^)(void))callbackToOrigin
{
    void (^limitOverrideBlock)(void) = ^{
        BuzzSentrySpanId *spanId
            = objc_getAssociatedObject(controller, &SENTRY_UI_PERFORMANCE_TRACKER_SPAN_ID);

        if (spanId == nil || ![self.tracker isSpanAlive:spanId]) {
            // We are no longer tracking this UIViewController, just call the base
            // method.
            callbackToOrigin();
            return;
        }

        void (^duringBlock)(void) = ^{
            BuzzSentrySpanId *viewAppearingId = objc_getAssociatedObject(
                controller, &SENTRY_UI_PERFORMANCE_TRACKER_VIEWAPPEARING_SPAN_ID);
            if (viewAppearingId != nil) {
                [self.tracker finishSpan:viewAppearingId withStatus:status];
                objc_setAssociatedObject(controller,
                    &SENTRY_UI_PERFORMANCE_TRACKER_VIEWAPPEARING_SPAN_ID, nil,
                    OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }

            [self.tracker measureSpanWithDescription:lifecycleMethod
                                          nameSource:kBuzzSentryTransactionNameSourceComponent
                                           operation:BuzzSentrySpanOperationUILoad
                                             inBlock:callbackToOrigin];
        };
        [self.tracker activateSpan:spanId duringBlock:duringBlock];

        // If we are still tracking this UIViewController finish the transaction
        // and remove associated span id.
        [self.tracker finishSpan:spanId withStatus:status];
        objc_setAssociatedObject(controller, &SENTRY_UI_PERFORMANCE_TRACKER_SPAN_ID, nil,
            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    };

    [self limitOverride:lifecycleMethod
                  target:controller
        callbackToOrigin:callbackToOrigin
                   block:limitOverrideBlock];
}

- (void)viewControllerViewWillLayoutSubViews:(UIViewController *)controller
                            callbackToOrigin:(void (^)(void))callbackToOrigin
{
    void (^limitOverrideBlock)(void) = ^{
        BuzzSentrySpanId *spanId
            = objc_getAssociatedObject(controller, &SENTRY_UI_PERFORMANCE_TRACKER_SPAN_ID);

        if (spanId == nil || ![self.tracker isSpanAlive:spanId]) {
            // We are no longer tracking this UIViewController, just call the base
            // method.
            callbackToOrigin();
            return;
        }

        void (^duringBlock)(void) = ^{
            [self.tracker measureSpanWithDescription:@"viewWillLayoutSubviews"
                                          nameSource:kBuzzSentryTransactionNameSourceComponent
                                           operation:BuzzSentrySpanOperationUILoad
                                             inBlock:callbackToOrigin];

            BuzzSentrySpanId *layoutSubViewId =
                [self.tracker startSpanWithName:@"layoutSubViews"
                                     nameSource:kBuzzSentryTransactionNameSourceComponent
                                      operation:BuzzSentrySpanOperationUILoad];

            objc_setAssociatedObject(controller,
                &SENTRY_UI_PERFORMANCE_TRACKER_LAYOUTSUBVIEW_SPAN_ID, layoutSubViewId,
                OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        };
        [self.tracker activateSpan:spanId duringBlock:duringBlock];
    };

    [self limitOverride:@"viewWillLayoutSubviews"
                  target:controller
        callbackToOrigin:callbackToOrigin
                   block:limitOverrideBlock];
}

- (void)viewControllerViewDidLayoutSubViews:(UIViewController *)controller
                           callbackToOrigin:(void (^)(void))callbackToOrigin
{
    void (^limitOverrideBlock)(void) = ^{
        BuzzSentrySpanId *spanId
            = objc_getAssociatedObject(controller, &SENTRY_UI_PERFORMANCE_TRACKER_SPAN_ID);

        if (spanId == nil || ![self.tracker isSpanAlive:spanId]) {
            // We are no longer tracking this UIViewController, just call the base
            // method.
            callbackToOrigin();
            return;
        }

        void (^duringBlock)(void) = ^{
            BuzzSentrySpanId *layoutSubViewId = objc_getAssociatedObject(
                controller, &SENTRY_UI_PERFORMANCE_TRACKER_LAYOUTSUBVIEW_SPAN_ID);

            if (layoutSubViewId != nil) {
                [self.tracker finishSpan:layoutSubViewId];
            }

            [self.tracker measureSpanWithDescription:@"viewDidLayoutSubviews"
                                          nameSource:kBuzzSentryTransactionNameSourceComponent
                                           operation:BuzzSentrySpanOperationUILoad
                                             inBlock:callbackToOrigin];

            objc_setAssociatedObject(controller,
                &SENTRY_UI_PERFORMANCE_TRACKER_LAYOUTSUBVIEW_SPAN_ID, nil,
                OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        };

        [self.tracker activateSpan:spanId duringBlock:duringBlock];
    };

    [self limitOverride:@"viewDidLayoutSubviews"
                  target:controller
        callbackToOrigin:callbackToOrigin
                   block:limitOverrideBlock];
}

/**
 * When a custom UIViewController is a subclass of another custom UIViewController, the SDK swizzles
 * both functions, which would create one span for each UIViewController leading to duplicate spans
 * in the transaction. To fix this, we only allow one span per lifecycle method at a time.
 */
- (void)limitOverride:(NSString *)description
               target:(UIViewController *)viewController
     callbackToOrigin:(void (^)(void))callbackToOrigin
                block:(void (^)(void))block

{
    NSMutableSet<NSString *> *spansInExecution;

    spansInExecution = objc_getAssociatedObject(
        viewController, &SENTRY_UI_PERFORMANCE_TRACKER_SPANS_IN_EXECUTION_SET);
    if (spansInExecution == nil) {
        spansInExecution = [[NSMutableSet alloc] init];
        objc_setAssociatedObject(viewController,
            &SENTRY_UI_PERFORMANCE_TRACKER_SPANS_IN_EXECUTION_SET, spansInExecution,
            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (![spansInExecution containsObject:description]) {
        [spansInExecution addObject:description];
        block();
        [spansInExecution removeObject:description];
    } else {
        callbackToOrigin();
    }
}

- (void)measurePerformance:(NSString *)description
                    target:(UIViewController *)viewController
          callbackToOrigin:(void (^)(void))callbackToOrigin
{
    BuzzSentrySpanId *spanId
        = objc_getAssociatedObject(viewController, &SENTRY_UI_PERFORMANCE_TRACKER_SPAN_ID);

    if (spanId == nil) {
        // We are no longer tracking this UIViewController, just call the base method.
        callbackToOrigin();
    } else {
        [self.tracker measureSpanWithDescription:description
                                      nameSource:kBuzzSentryTransactionNameSourceComponent
                                       operation:BuzzSentrySpanOperationUILoad
                                    parentSpanId:spanId
                                         inBlock:callbackToOrigin];
    }
}
#endif

@end
