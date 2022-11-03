#import "NSData+BuzzSentry.h"

@implementation
NSData (BuzzSentry)

- (NSData *)sentry_nullTerminated
{
    if (self == nil) {
        return nil;
    }
    NSMutableData *mutable = [NSMutableData dataWithData:self];
    [mutable appendBytes:"\0" length:1];
    return mutable;
}

@end
