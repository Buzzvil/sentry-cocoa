#import "BuzzSentryNetworkTrackingIntegration.h"
#import "SentryLog.h"
#import "BuzzSentryNSURLSessionTaskSearch.h"
#import "BuzzSentryNetworkTracker.h"
#import "BuzzSentryOptions.h"
#import "BuzzSentrySwizzle.h"
#import <objc/runtime.h>

@implementation BuzzSentryNetworkTrackingIntegration

- (BOOL)installWithOptions:(BuzzSentryOptions *)options
{
    if (!options.enableSwizzling) {
        [self logWithOptionName:@"enableSwizzling"];
        return NO;
    }

    BOOL shouldEnableNetworkTracking = [super shouldBeEnabledWithOptions:options];

    if (shouldEnableNetworkTracking) {
        [BuzzSentryNetworkTracker.sharedInstance enableNetworkTracking];
    }

    if (options.enableNetworkBreadcrumbs) {
        [BuzzSentryNetworkTracker.sharedInstance enableNetworkBreadcrumbs];
    }

    if (shouldEnableNetworkTracking || options.enableNetworkBreadcrumbs) {
        [BuzzSentryNetworkTrackingIntegration swizzleURLSessionTask];
        return YES;
    } else {
        return NO;
    }
}

- (BuzzSentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionIsTracingEnabled | kIntegrationOptionEnableAutoPerformanceTracking
        | kIntegrationOptionEnableNetworkTracking;
}

- (void)uninstall
{
    [BuzzSentryNetworkTracker.sharedInstance disable];
}

// BuzzSentrySwizzleInstanceMethod declaration shadows a local variable. The swizzling is working
// fine and we accept this warning.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshadow"

+ (void)swizzleURLSessionTask
{
    NSArray<Class> *classesToSwizzle = [BuzzSentryNSURLSessionTaskSearch urlSessionTaskClassesToTrack];

    SEL setStateSelector = NSSelectorFromString(@"setState:");
    SEL resumeSelector = NSSelectorFromString(@"resume");

    for (Class classToSwizzle in classesToSwizzle) {
        BuzzSentrySwizzleInstanceMethod(classToSwizzle, resumeSelector, SentrySWReturnType(void),
            SentrySWArguments(), SentrySWReplacement({
                [BuzzSentryNetworkTracker.sharedInstance urlSessionTaskResume:self];
                SentrySWCallOriginal();
            }),
            BuzzSentrySwizzleModeOncePerClassAndSuperclasses, (void *)resumeSelector);

        BuzzSentrySwizzleInstanceMethod(classToSwizzle, setStateSelector, SentrySWReturnType(void),
            SentrySWArguments(NSURLSessionTaskState state), SentrySWReplacement({
                [BuzzSentryNetworkTracker.sharedInstance urlSessionTask:self setState:state];
                SentrySWCallOriginal(state);
            }),
            BuzzSentrySwizzleModeOncePerClassAndSuperclasses, (void *)setStateSelector);
    }
}

#pragma clang diagnostic pop

@end
