#import "BuzzSentryDataCategory.h"
#import "BuzzSentryDiscardReason.h"
#import "BuzzSentrySerializable.h"

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryDiscardedEvent : NSObject <BuzzSentrySerializable>
SENTRY_NO_INIT

- (instancetype)initWithReason:(BuzzSentryDiscardReason)reason
                      category:(BuzzSentryDataCategory)category
                      quantity:(NSUInteger)quantity;

@property (nonatomic, assign, readonly) BuzzSentryDiscardReason reason;
@property (nonatomic, assign, readonly) BuzzSentryDataCategory category;
@property (nonatomic, assign, readonly) NSUInteger quantity;

@end

NS_ASSUME_NONNULL_END
