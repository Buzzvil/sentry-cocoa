#import "BuzzSentryIntegrationProtocol.h"
#import <Foundation/Foundation.h>

@class BuzzSentryOptions;

NS_ASSUME_NONNULL_BEGIN

@interface SentryTestIntegration : NSObject <BuzzSentryIntegrationProtocol>

@property (nonatomic, strong) BuzzSentryOptions *options;

@end

NS_ASSUME_NONNULL_END
