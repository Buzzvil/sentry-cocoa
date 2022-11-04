#import "BuzzSentryANRTrackingIntegration.h"
#import "BuzzSentryANRTracker.h"
#import "BuzzSentryClient+Private.h"
#import "BuzzSentryCrashMachineContext.h"
#import "BuzzSentryCrashWrapper.h"
#import "BuzzSentryDefaultCurrentDateProvider.h"
#import "BuzzSentryDispatchQueueWrapper.h"
#import "BuzzSentryEvent.h"
#import "BuzzSentryException.h"
#import "BuzzSentryHub+Private.h"
#import "BuzzSentryMechanism.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentryThread.h"
#import "BuzzSentryThreadInspector.h"
#import "BuzzSentryThreadWrapper.h"
#import <BuzzSentryDependencyContainer.h>
#import <BuzzSentryOptions+Private.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryANRTrackingIntegration ()

@property (nonatomic, strong) BuzzSentryANRTracker *tracker;
@property (nonatomic, strong) BuzzSentryOptions *options;

@end

@implementation BuzzSentryANRTrackingIntegration

- (BOOL)installWithOptions:(BuzzSentryOptions *)options
{
    if (![super installWithOptions:options]) {
        return NO;
    }

    self.tracker =
        [BuzzSentryDependencyContainer.sharedInstance getANRTracker:options.appHangTimeoutInterval];

    [self.tracker addListener:self];
    self.options = options;

    return YES;
}

- (BuzzSentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionEnableAppHangTracking | kIntegrationOptionDebuggerNotAttached;
}

- (void)uninstall
{
    [self.tracker removeListener:self];
}

- (void)anrDetected
{
    BuzzSentryThreadInspector *threadInspector = BuzzSentrySDK.currentHub.getClient.threadInspector;

    NSString *message = [NSString stringWithFormat:@"App hanging for at least %li ms.",
                                  (long)(self.options.appHangTimeoutInterval * 1000)];

    NSArray<BuzzSentryThread *> *threads = [threadInspector getCurrentThreadsWithStackTrace];

    BuzzSentryEvent *event = [[BuzzSentryEvent alloc] initWithLevel:kSentryLevelError];
    BuzzSentryException *sentryException = [[BuzzSentryException alloc] initWithValue:message
                                                                         type:@"App Hanging"];
    sentryException.mechanism = [[BuzzSentryMechanism alloc] initWithType:@"AppHang"];
    sentryException.stacktrace = [threads[0] stacktrace];
    [threads enumerateObjectsUsingBlock:^(BuzzSentryThread *_Nonnull obj, NSUInteger idx,
        BOOL *_Nonnull stop) { obj.current = [NSNumber numberWithBool:idx == 0]; }];

    event.exceptions = @[ sentryException ];
    event.threads = threads;

    [BuzzSentrySDK captureEvent:event];
}

- (void)anrStopped
{
    // We dont report when an ANR ends.
}

@end

NS_ASSUME_NONNULL_END
