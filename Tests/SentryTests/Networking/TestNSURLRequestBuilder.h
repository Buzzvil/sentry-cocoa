#import "BuzzSentryNSURLRequestBuilder.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestNSURLRequestBuilder : BuzzSentryNSURLRequestBuilder

@property (nonatomic, assign) BOOL shouldFailWithError;

@end

NS_ASSUME_NONNULL_END
