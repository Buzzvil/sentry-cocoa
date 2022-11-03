#import "SentryCrash.h"
#import "SentryDefines.h"
#import <Foundation/Foundation.h>

@class BuzzSentryInAppLogic, BuzzSentryCrashWrapper, BuzzSentryDispatchQueueWrapper;

NS_ASSUME_NONNULL_BEGIN

@interface SentryCrashReportSink : NSObject <SentryCrashReportFilter>
SENTRY_NO_INIT

- (instancetype)initWithInAppLogic:(BuzzSentryInAppLogic *)inAppLogic
                      crashWrapper:(BuzzSentryCrashWrapper *)crashWrapper
                     dispatchQueue:(BuzzSentryDispatchQueueWrapper *)dispatchQueue;

@end

NS_ASSUME_NONNULL_END
