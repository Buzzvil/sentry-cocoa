#import "SentryTestIntegration.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SentryTestIntegration

- (BOOL)installWithOptions:(BuzzSentryOptions *)options
{
    self.options = options;
    return YES;
}

@end

NS_ASSUME_NONNULL_END
