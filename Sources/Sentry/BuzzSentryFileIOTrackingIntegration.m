#import "BuzzSentryFileIOTrackingIntegration.h"
#import "SentryLog.h"
#import "BuzzSentryNSDataSwizzling.h"
#import "BuzzSentryOptions.h"

@implementation BuzzSentryFileIOTrackingIntegration

- (BOOL)installWithOptions:(BuzzSentryOptions *)options
{
    if (![super installWithOptions:options]) {
        return NO;
    }

    [BuzzSentryNSDataSwizzling start];

    return YES;
}

- (BuzzSentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionEnableSwizzling | kIntegrationOptionIsTracingEnabled
        | kIntegrationOptionEnableAutoPerformanceTracking | kIntegrationOptionEnableFileIOTracking;
}

- (void)uninstall
{
    [BuzzSentryNSDataSwizzling stop];
}

@end
