#import "BuzzSentrySession.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NSString *nameForBuzzSentrySessionStatus(BuzzSentrySessionStatus status);

@interface
BuzzSentrySession (Private)

- (void)setFlagInit;

@end

NS_ASSUME_NONNULL_END
