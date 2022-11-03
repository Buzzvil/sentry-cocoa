#import "BuzzSentryAutoBreadcrumbTrackingIntegration.h"
#import "BuzzSentryBreadcrumbTracker.h"
#import "SentryDefaultCurrentDateProvider.h"
#import "SentryDependencyContainer.h"
#import "SentryFileManager.h"
#import "SentryLog.h"
#import "BuzzSentryOptions.h"
#import "BuzzSentrySystemEventBreadcrumbs.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryAutoBreadcrumbTrackingIntegration ()

@property (nonatomic, strong) BuzzSentryBreadcrumbTracker *breadcrumbTracker;
@property (nonatomic, strong) BuzzSentrySystemEventBreadcrumbs *systemEventBreadcrumbs;

@end

@implementation BuzzSentryAutoBreadcrumbTrackingIntegration

- (BOOL)installWithOptions:(nonnull BuzzSentryOptions *)options
{
    if (![super installWithOptions:options]) {
        return NO;
    }

    [self installWithOptions:options
             breadcrumbTracker:[[BuzzSentryBreadcrumbTracker alloc]
                                   initWithSwizzleWrapper:[SentryDependencyContainer sharedInstance]
                                                              .swizzleWrapper]
        systemEventBreadcrumbs:[[BuzzSentrySystemEventBreadcrumbs alloc]
                                      initWithFileManager:[SentryDependencyContainer sharedInstance]
                                                              .fileManager
                                   andCurrentDateProvider:[SentryDefaultCurrentDateProvider
                                                              sharedInstance]]];

    return YES;
}

- (SentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionEnableAutoBreadcrumbTracking;
}

/**
 * For testing.
 */
- (void)installWithOptions:(nonnull BuzzSentryOptions *)options
         breadcrumbTracker:(BuzzSentryBreadcrumbTracker *)breadcrumbTracker
    systemEventBreadcrumbs:(BuzzSentrySystemEventBreadcrumbs *)systemEventBreadcrumbs
{
    self.breadcrumbTracker = breadcrumbTracker;
    [self.breadcrumbTracker start];

    if (options.enableSwizzling) {
        [self.breadcrumbTracker startSwizzle];
    }

    self.systemEventBreadcrumbs = systemEventBreadcrumbs;
    [self.systemEventBreadcrumbs start];
}

- (void)uninstall
{
    if (nil != self.breadcrumbTracker) {
        [self.breadcrumbTracker stop];
    }
    if (nil != self.systemEventBreadcrumbs) {
        [self.systemEventBreadcrumbs stop];
    }
}

@end

NS_ASSUME_NONNULL_END