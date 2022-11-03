#import "SentryCrash.h"
#import "SentryCrashInstallation.h"
#import "SentryDefines.h"
#import <Foundation/Foundation.h>

@class BuzzSentryInAppLogic, BuzzSentryCrashWrapper, BuzzSentryDispatchQueueWrapper;

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryCrashInstallationReporter : SentryCrashInstallation
SENTRY_NO_INIT

- (instancetype)initWithInAppLogic:(BuzzSentryInAppLogic *)inAppLogic
                      crashWrapper:(BuzzSentryCrashWrapper *)crashWrapper
                     dispatchQueue:(BuzzSentryDispatchQueueWrapper *)dispatchQueue;

- (void)sendAllReports;

@end

NS_ASSUME_NONNULL_END
