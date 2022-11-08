#import "BuzzSentryDiscardedEvent.h"
#import "BuzzSentryDataCategoryMapper.h"
#import "BuzzSentryDiscardReasonMapper.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryDiscardedEvent

- (instancetype)initWithReason:(BuzzSentryDiscardReason)reason
                      category:(BuzzSentryDataCategory)category
                      quantity:(NSUInteger)quantity
{
    if (self = [super init]) {
        _reason = reason;
        _category = category;
        _quantity = quantity;
    }
    return self;
}

- (NSDictionary<NSString *, id> *)serialize
{
    return @{
        @"reason" : nameForBuzzSentryDiscardReason(self.reason),
        @"category" : nameForBuzzSentryDataCategory(self.category),
        @"quantity" : @(self.quantity)
    };
}

@end

NS_ASSUME_NONNULL_END
