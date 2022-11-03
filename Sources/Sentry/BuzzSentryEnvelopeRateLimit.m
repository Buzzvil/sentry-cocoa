#import "BuzzSentryEnvelopeRateLimit.h"
#import "SentryDataCategoryMapper.h"
#import "BuzzSentryEnvelope.h"
#import "BuzzSentryRateLimits.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryEnvelopeRateLimit ()

@property (nonatomic, strong) id<BuzzSentryRateLimits> rateLimits;
@property (nonatomic, weak) id<BuzzSentryEnvelopeRateLimitDelegate> delegate;

@end

@implementation BuzzSentryEnvelopeRateLimit

- (instancetype)initWithRateLimits:(id<BuzzSentryRateLimits>)sentryRateLimits
{
    if (self = [super init]) {
        self.rateLimits = sentryRateLimits;
    }
    return self;
}

- (void)setDelegate:(id<BuzzSentryEnvelopeRateLimitDelegate>)delegate
{
    _delegate = delegate;
}

- (BuzzSentryEnvelope *)removeRateLimitedItems:(BuzzSentryEnvelope *)envelope
{
    if (nil == envelope) {
        return envelope;
    }

    BuzzSentryEnvelope *result = envelope;

    NSArray<BuzzSentryEnvelopeItem *> *itemsToDrop = [self getEnvelopeItemsToDrop:envelope.items];

    if (itemsToDrop.count > 0) {
        NSArray<BuzzSentryEnvelopeItem *> *itemsToSend = [self getItemsToSend:envelope.items
                                                          withItemsToDrop:itemsToDrop];

        result = [[BuzzSentryEnvelope alloc] initWithHeader:envelope.header items:itemsToSend];
    }

    return result;
}

- (NSArray<BuzzSentryEnvelopeItem *> *)getEnvelopeItemsToDrop:(NSArray<BuzzSentryEnvelopeItem *> *)items
{
    NSMutableArray<BuzzSentryEnvelopeItem *> *itemsToDrop = [NSMutableArray new];

    for (BuzzSentryEnvelopeItem *item in items) {
        SentryDataCategory rateLimitCategory
            = sentryDataCategoryForEnvelopItemType(item.header.type);
        if ([self.rateLimits isRateLimitActive:rateLimitCategory]) {
            [itemsToDrop addObject:item];
            [self.delegate envelopeItemDropped:rateLimitCategory];
        }
    }

    return itemsToDrop;
}

- (NSArray<BuzzSentryEnvelopeItem *> *)getItemsToSend:(NSArray<BuzzSentryEnvelopeItem *> *)allItems
                                  withItemsToDrop:
                                      (NSArray<BuzzSentryEnvelopeItem *> *_Nonnull)itemsToDrop
{
    NSMutableArray<BuzzSentryEnvelopeItem *> *itemsToSend = [NSMutableArray new];

    for (BuzzSentryEnvelopeItem *item in allItems) {
        if (![itemsToDrop containsObject:item]) {
            [itemsToSend addObject:item];
        }
    }

    return itemsToSend;
}

@end

NS_ASSUME_NONNULL_END
