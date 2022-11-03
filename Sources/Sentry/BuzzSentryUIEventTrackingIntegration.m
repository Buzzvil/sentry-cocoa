#import "BuzzSentryUIEventTrackingIntegration.h"
#import <Foundation/Foundation.h>
#import <BuzzSentryDependencyContainer.h>
#import <BuzzSentryLog.h>
#import <BuzzSentryNSDataSwizzling.h>
#import <BuzzSentryOptions+Private.h>
#import <BuzzSentryOptions.h>
#import <BuzzSentryUIEventTracker.h>

#if SENTRY_HAS_UIKIT
@interface
BuzzSentryUIEventTrackingIntegration ()

@property (nonatomic, strong) BuzzSentryUIEventTracker *uiEventTracker;

@end

@implementation BuzzSentryUIEventTrackingIntegration

- (BOOL)installWithOptions:(BuzzSentryOptions *)options
{
    if (![super installWithOptions:options]) {
        return NO;
    }

    BuzzSentryDependencyContainer *dependencies = [BuzzSentryDependencyContainer sharedInstance];
    self.uiEventTracker = [[BuzzSentryUIEventTracker alloc]
        initWithSwizzleWrapper:[BuzzSentryDependencyContainer sharedInstance].swizzleWrapper
          dispatchQueueWrapper:dependencies.dispatchQueueWrapper
                   idleTimeout:options.idleTimeout];

    [self.uiEventTracker start];

    return YES;
}

- (BuzzSentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionEnableAutoPerformanceTracking | kIntegrationOptionEnableSwizzling
        | kIntegrationOptionIsTracingEnabled | kIntegrationOptionEnableUserInteractionTracing;
}

- (void)uninstall
{
    if (self.uiEventTracker) {
        [self.uiEventTracker stop];
    }
}

@end
#endif
