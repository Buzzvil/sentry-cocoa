#import "AppDelegate.h"
@import CoreData;
@import BuzzSentry;

@interface
AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    [BuzzSentrySDK startWithConfigureOptions:^(BuzzSentryOptions *options) {
        options.dsn = @"https://aef14cb82ad6405890fb7a536ba7f4fa@o4459.ingest.sentry.io/6261456";
        options.debug = YES;
        options.sessionTrackingIntervalMillis = 5000UL;
        // Sampling 100% - In Production you probably want to adjust this
        options.tracesSampleRate = @1.0;
        options.enableFileIOTracking = YES;
        options.attachScreenshot = YES;
        options.attachViewHierarchy = YES;
        options.enableUserInteractionTracing = YES;
        if ([NSProcessInfo.processInfo.arguments containsObject:@"--io.sentry.profiling.enable"]) {
            options.profilesSampleRate = @1;
        }
        options.enableCaptureFailedRequests = YES;
        BuzzSentryHttpStatusCodeRange *httpStatusCodeRange =
            [[BuzzSentryHttpStatusCodeRange alloc] initWithMin:400 max:599];
        options.failedRequestStatusCodes = @[ httpStatusCodeRange ];
    }];

    return YES;
}

#pragma mark - UISceneSession lifecycle

@end
