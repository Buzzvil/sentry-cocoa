#import "BuzzSentryCrashInstallationReporter.h"
#import "SentryCrash.h"
#import "SentryCrashInstallation+Private.h"
#import "BuzzSentryCrashReportSink.h"
#import "SentryDefines.h"
#import "BuzzSentryLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryCrashInstallationReporter ()

@property (nonatomic, strong) BuzzSentryInAppLogic *inAppLogic;
@property (nonatomic, strong) BuzzSentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) BuzzSentryDispatchQueueWrapper *dispatchQueue;

@end

@implementation BuzzSentryCrashInstallationReporter

- (instancetype)initWithInAppLogic:(BuzzSentryInAppLogic *)inAppLogic
                      crashWrapper:(BuzzSentryCrashWrapper *)crashWrapper
                     dispatchQueue:(BuzzSentryDispatchQueueWrapper *)dispatchQueue
{
    if (self = [super initWithRequiredProperties:[NSArray new]]) {
        self.inAppLogic = inAppLogic;
        self.crashWrapper = crashWrapper;
        self.dispatchQueue = dispatchQueue;
    }
    return self;
}

- (id<SentryCrashReportFilter>)sink
{
    return [[BuzzSentryCrashReportSink alloc] initWithInAppLogic:self.inAppLogic
                                                crashWrapper:self.crashWrapper
                                               dispatchQueue:self.dispatchQueue];
}

- (void)sendAllReports
{
    [self sendAllReportsWithCompletion:NULL];
}

- (void)sendAllReportsWithCompletion:(SentryCrashReportFilterCompletion)onCompletion
{
    [super
        sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
            if (nil != error) {
                SENTRY_LOG_ERROR(@"%@", error.localizedDescription);
            }
            SENTRY_LOG_DEBUG(@"Sent %lu crash report(s)", (unsigned long)filteredReports.count);
            if (completed && onCompletion) {
                onCompletion(filteredReports, completed, error);
            }
        }];
}

@end

NS_ASSUME_NONNULL_END
