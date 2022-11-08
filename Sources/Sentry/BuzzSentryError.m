#import "BuzzSentryError.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const BuzzSentryErrorDomain = @"BuzzSentryErrorDomain";

NSError *_Nullable NSErrorFromBuzzSentryError(BuzzSentryError error, NSString *description)
{
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:BuzzSentryErrorDomain code:error userInfo:userInfo];
}

NS_ASSUME_NONNULL_END
