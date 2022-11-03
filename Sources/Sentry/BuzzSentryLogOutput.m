#import "BuzzSentryLogOutput.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryLogOutput

- (void)log:(NSString *)message
{
    NSLog(@"%@", message);
}

@end

NS_ASSUME_NONNULL_END
