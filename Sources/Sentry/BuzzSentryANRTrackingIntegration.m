#import "BuzzSentryANRTrackingIntegration.h"
#import "BuzzSentryANRTracker.h"
#import "BuzzSentryClient+Private.h"
#import "SentryCrashMachineContext.h"
#import "SentryCrashWrapper.h"
#import "SentryDefaultCurrentDateProvider.h"
#import "BuzzSentryDispatchQueueWrapper.h"
#import "BuzzSentryEvent.h"
#import "SentryException.h"
#import "SentryHub+Private.h"
#import "BuzzSentryMechanism.h"
#import "BuzzSentrySDK+Private.h"
#import "SentryThread.h"
#import "SentryThreadInspector.h"
#import "SentryThreadWrapper.h"
#import <SentryDependencyContainer.h>
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
        [SentryDependencyContainer.sharedInstance getANRTracker:options.appHangTimeoutInterval];

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
    SentryThreadInspector *threadInspector = SentrySDK.currentHub.getClient.threadInspector;

    NSString *message = [NSString stringWithFormat:@"App hanging for at least %li ms.",
                                  (long)(self.options.appHangTimeoutInterval * 1000)];

    NSArray<SentryThread *> *threads = [threadInspector getCurrentThreadsWithStackTrace];

    BuzzSentryEvent *event = [[BuzzSentryEvent alloc] initWithLevel:kSentryLevelError];
    SentryException *sentryException = [[SentryException alloc] initWithValue:message
                                                                         type:@"App Hanging"];
    sentryException.mechanism = [[BuzzSentryMechanism alloc] initWithType:@"AppHang"];
    sentryException.stacktrace = [threads[0] stacktrace];
    [threads enumerateObjectsUsingBlock:^(SentryThread *_Nonnull obj, NSUInteger idx,
        BOOL *_Nonnull stop) { obj.current = [NSNumber numberWithBool:idx == 0]; }];

    event.exceptions = @[ sentryException ];
    event.threads = threads;

    [SentrySDK captureEvent:event];
}

- (void)anrStopped
{
    // We dont report when an ANR ends.
}

@end

NS_ASSUME_NONNULL_END
