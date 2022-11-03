#import "BuzzSentryPerformanceTrackingIntegration.h"
#import "SentryDefaultObjCRuntimeWrapper.h"
#import "BuzzSentryDispatchQueueWrapper.h"
#import "SentryLog.h"
#import "BuzzSentrySubClassFinder.h"
#import "BuzzSentryUIViewControllerSwizzling.h"

@interface
BuzzSentryPerformanceTrackingIntegration ()

#if SENTRY_HAS_UIKIT
@property (nonatomic, strong) BuzzSentryUIViewControllerSwizzling *swizzling;
#endif

@end

@implementation BuzzSentryPerformanceTrackingIntegration

- (BOOL)installWithOptions:(BuzzSentryOptions *)options
{
#if SENTRY_HAS_UIKIT
    if (![super installWithOptions:options]) {
        return NO;
    }

    dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(
        DISPATCH_QUEUE_SERIAL, DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    BuzzSentryDispatchQueueWrapper *dispatchQueue =
        [[BuzzSentryDispatchQueueWrapper alloc] initWithName:"sentry-ui-view-controller-swizzling"
                                              attributes:attributes];

    BuzzSentrySubClassFinder *subClassFinder = [[BuzzSentrySubClassFinder alloc]
        initWithDispatchQueue:dispatchQueue
           objcRuntimeWrapper:[SentryDefaultObjCRuntimeWrapper sharedInstance]];

    self.swizzling = [[BuzzSentryUIViewControllerSwizzling alloc]
           initWithOptions:options
             dispatchQueue:dispatchQueue
        objcRuntimeWrapper:[SentryDefaultObjCRuntimeWrapper sharedInstance]
            subClassFinder:subClassFinder];

    [self.swizzling start];
    return YES;
#else
    SENTRY_LOG_DEBUG(@"NO UIKit -> [BuzzSentryPerformanceTrackingIntegration start] does nothing.");
    return NO;
#endif
}

- (BuzzSentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionEnableAutoPerformanceTracking
        | kIntegrationOptionEnableUIViewControllerTracking | kIntegrationOptionIsTracingEnabled
        | kIntegrationOptionEnableSwizzling;
}

@end
