#import "SentrySerializable.h"
#import <Foundation/Foundation.h>

@class BuzzSentryDiscardedEvent;

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryClientReport : NSObject <SentrySerializable>
SENTRY_NO_INIT

- (instancetype)initWithDiscardedEvents:(NSArray<BuzzSentryDiscardedEvent *> *)discardedEvents;

/**
 * The timestamp of when the client report was created.
 */
@property (nonatomic, strong, readonly) NSDate *timestamp;

@property (nonatomic, strong, readonly) NSArray<BuzzSentryDiscardedEvent *> *discardedEvents;

@end

NS_ASSUME_NONNULL_END
