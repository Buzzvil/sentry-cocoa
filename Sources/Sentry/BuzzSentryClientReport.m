#import "BuzzSentryClientReport.h"
#import "BuzzSentryCurrentDate.h"
#import <Foundation/Foundation.h>
#import <BuzzSentryDiscardedEvent.h>

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryClientReport

- (instancetype)initWithDiscardedEvents:(NSArray<BuzzSentryDiscardedEvent *> *)discardedEvents
{
    if (self = [super init]) {
        _timestamp = [BuzzSentryCurrentDate date];
        _discardedEvents = discardedEvents;
    }
    return self;
}

- (NSDictionary<NSString *, id> *)serialize
{
    NSMutableArray<NSDictionary<NSString *, id> *> *events =
        [[NSMutableArray alloc] initWithCapacity:self.discardedEvents.count];
    for (BuzzSentryDiscardedEvent *event in self.discardedEvents) {
        [events addObject:[event serialize]];
    }

    return
        @{ @"timestamp" : @(self.timestamp.timeIntervalSince1970), @"discarded_events" : events };
}

@end

NS_ASSUME_NONNULL_END
