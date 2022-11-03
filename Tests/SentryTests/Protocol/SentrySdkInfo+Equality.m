#import "BuzzSentrySDKInfo+Equality.h"

@implementation
BuzzSentrySDKInfo (Equality)

- (BOOL)isEqual:(id _Nullable)object
{
    if (object == self)
        return YES;
    if ([self class] != [object class])
        return NO;

    BuzzSentrySDKInfo *otherSdkInfo = (BuzzSentrySDKInfo *)object;

    if (![self.name isEqualToString:otherSdkInfo.name]) {
        return NO;
    }

    if (![self.version isEqualToString:otherSdkInfo.version]) {
        return NO;
    }

    return YES;
}

- (NSUInteger)hash
{
    NSUInteger hash = 17;

    hash = hash * 23 + [self.name hash];
    hash = hash * 23 + [self.version hash];

    return hash;
}

@end
