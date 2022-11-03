#import "BuzzSentryCoreDataTrackingIntegration.h"
#import "BuzzSentryCoreDataSwizzling.h"
#import "BuzzSentryCoreDataTracker.h"
#import "SentryLog.h"
#import "BuzzSentryNSDataSwizzling.h"
#import "BuzzSentryOptions.h"

@interface
BuzzSentryCoreDataTrackingIntegration ()

@property (nonatomic, strong) BuzzSentryCoreDataTracker *tracker;

@end

@implementation BuzzSentryCoreDataTrackingIntegration

- (BOOL)installWithOptions:(BuzzSentryOptions *)options
{
    if (![super installWithOptions:options]) {
        return NO;
    }

    self.tracker = [[BuzzSentryCoreDataTracker alloc] init];
    [BuzzSentryCoreDataSwizzling.sharedInstance startWithMiddleware:self.tracker];

    return YES;
}

- (SentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionEnableAutoPerformanceTracking | kIntegrationOptionEnableSwizzling
        | kIntegrationOptionIsTracingEnabled | kIntegrationOptionEnableCoreDataTracking;
}

- (void)uninstall
{
    [BuzzSentryCoreDataSwizzling.sharedInstance stop];
}

@end
