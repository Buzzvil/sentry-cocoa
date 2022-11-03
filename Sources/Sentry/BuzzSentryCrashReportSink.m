#import "BuzzSentryCrashReportSink.h"
#import "BuzzSentryAttachment.h"
#import "BuzzSentryClient.h"
#import "SentryCrash.h"
#include "SentryCrashMonitor_AppState.h"
#import "BuzzSentryCrashReportConverter.h"
#import "BuzzSentryCrashWrapper.h"
#import "BuzzSentryDefines.h"
#import "BuzzSentryDispatchQueueWrapper.h"
#import "BuzzSentryEvent.h"
#import "SentryException.h"
#import "BuzzSentryHub.h"
#import "BuzzSentryLog.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentrySDK.h"
#import "BuzzSentryScope.h"
#import "SentryThread.h"

static const NSTimeInterval SENTRY_APP_START_CRASH_DURATION_THRESHOLD = 2.0;
static const NSTimeInterval SENTRY_APP_START_CRASH_FLUSH_DURATION = 5.0;

@interface
BuzzSentryCrashReportSink ()

@property (nonatomic, strong) BuzzSentryInAppLogic *inAppLogic;
@property (nonatomic, strong) BuzzSentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) BuzzSentryDispatchQueueWrapper *dispatchQueue;

@end

@implementation BuzzSentryCrashReportSink

- (instancetype)initWithInAppLogic:(BuzzSentryInAppLogic *)inAppLogic
                      crashWrapper:(BuzzSentryCrashWrapper *)crashWrapper
                     dispatchQueue:(BuzzSentryDispatchQueueWrapper *)dispatchQueue
{
    if (self = [super init]) {
        self.inAppLogic = inAppLogic;
        self.crashWrapper = crashWrapper;
        self.dispatchQueue = dispatchQueue;
    }
    return self;
}

- (void)filterReports:(NSArray *)reports
         onCompletion:(SentryCrashReportFilterCompletion)onCompletion
{
    NSTimeInterval durationFromCrashStateInitToLastCrash
        = self.crashWrapper.durationFromCrashStateInitToLastCrash;
    if (durationFromCrashStateInitToLastCrash > 0
        && durationFromCrashStateInitToLastCrash <= SENTRY_APP_START_CRASH_DURATION_THRESHOLD) {
        SENTRY_LOG_WARN(@"Startup crash: detected.");
        [self sendReports:reports onCompletion:onCompletion];

        [BuzzSentrySDK flush:SENTRY_APP_START_CRASH_FLUSH_DURATION];
        SENTRY_LOG_DEBUG(@"Startup crash: Finished flushing.");

    } else {
        [self.dispatchQueue
            dispatchAsyncWithBlock:^{ [self sendReports:reports onCompletion:onCompletion]; }];
    }
}

- (void)sendReports:(NSArray *)reports onCompletion:(SentryCrashReportFilterCompletion)onCompletion
{
    NSMutableArray *sentReports = [NSMutableArray new];
    for (NSDictionary *report in reports) {
        BuzzSentryCrashReportConverter *reportConverter =
            [[BuzzSentryCrashReportConverter alloc] initWithReport:report inAppLogic:self.inAppLogic];
        if (nil != [BuzzSentrySDK.currentHub getClient]) {
            BuzzSentryEvent *event = [reportConverter convertReportToEvent];
            if (nil != event) {
                [self handleConvertedEvent:event report:report sentReports:sentReports];
            }
        } else {
            SENTRY_LOG_ERROR(
                @"Crash reports were found but no [BuzzSentrySDK.currentHub getClient] is set. "
                @"Cannot send crash reports to Sentry. This is probably a misconfiguration, "
                @"make sure you set the client with [BuzzSentrySDK.currentHub bindClient] before "
                @"calling startCrashHandlerWithError:.");
        }
    }
    if (onCompletion) {
        onCompletion(sentReports, TRUE, nil);
    }
}

- (void)handleConvertedEvent:(BuzzSentryEvent *)event
                      report:(NSDictionary *)report
                 sentReports:(NSMutableArray *)sentReports
{
    [sentReports addObject:report];
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] initWithScope:BuzzSentrySDK.currentHub.scope];

    if (report[SENTRYCRASH_REPORT_ATTACHMENTS_ITEM]) {
        for (NSString *ssPath in report[SENTRYCRASH_REPORT_ATTACHMENTS_ITEM]) {
            [scope addAttachment:[[BuzzSentryAttachment alloc] initWithPath:ssPath]];
        }
    }

    [BuzzSentrySDK captureCrashEvent:event withScope:scope];
}

@end
