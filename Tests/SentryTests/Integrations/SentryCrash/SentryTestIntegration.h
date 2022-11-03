#import "SentryIntegrationProtocol.h"
#import <Foundation/Foundation.h>

@class BuzzSentryOptions;

NS_ASSUME_NONNULL_BEGIN

@interface SentryTestIntegration : NSObject <SentryIntegrationProtocol>

@property (nonatomic, strong) BuzzSentryOptions *options;

@end

NS_ASSUME_NONNULL_END
