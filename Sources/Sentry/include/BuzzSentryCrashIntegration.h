#import "BuzzSentryBaseIntegration.h"
#import "BuzzSentryIntegrationProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryScope, BuzzSentryCrashWrapper;

static NSString *const SentryDeviceContextFreeMemoryKey = @"free_memory";
static NSString *const SentryDeviceContextAppMemoryKey = @"app_memory";

@interface BuzzSentryCrashIntegration : BuzzSentryBaseIntegration <BuzzSentryIntegrationProtocol>

+ (void)enrichScope:(BuzzSentryScope *)scope crashWrapper:(BuzzSentryCrashWrapper *)crashWrapper;

/**
 * Needed for testing.
 */
+ (void)sendAllSentryCrashReports;

@end

NS_ASSUME_NONNULL_END
