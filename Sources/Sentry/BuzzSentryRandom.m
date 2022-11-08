#import "BuzzSentryRandom.h"

@implementation BuzzSentryRandom

- (instancetype)init
{
    if (self = [super init]) {
        srand48(time(0)); // drand seed initializer
    }
    return self;
}

- (double)nextNumber
{
    return drand48();
}

@end
