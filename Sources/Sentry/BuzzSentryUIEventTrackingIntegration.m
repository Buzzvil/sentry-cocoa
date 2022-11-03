#import "BuzzSentryUIEventTrackingIntegration.h"
#import <Foundation/Foundation.h>
#import <SentryDependencyContainer.h>
#import <SentryLog.h>
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

    SentryDependencyContainer *dependencies = [SentryDependencyContainer sharedInstance];
    self.uiEventTracker = [[BuzzSentryUIEventTracker alloc]
        initWithSwizzleWrapper:[SentryDependencyContainer sharedInstance].swizzleWrapper
          dispatchQueueWrapper:dependencies.dispatchQueueWrapper
                   idleTimeout:options.idleTimeout];

    [self.uiEventTracker start];

    return YES;
}

- (SentryIntegrationOption)integrationOptions
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
