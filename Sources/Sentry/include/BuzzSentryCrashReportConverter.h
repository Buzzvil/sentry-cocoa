#import <Foundation/Foundation.h>

@class BuzzSentryEvent, SentryInAppLogic;

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryCrashReportConverter : NSObject

@property (nonatomic, strong) NSDictionary *userContext;

- (instancetype)initWithReport:(NSDictionary *)report inAppLogic:(SentryInAppLogic *)inAppLogic;

/**
 * Converts the report to an BuzzSentryEvent.
 *
 * @return The converted event or nil if an error occurred during the conversion.
 */
- (BuzzSentryEvent *_Nullable)convertReportToEvent;

@end

NS_ASSUME_NONNULL_END
