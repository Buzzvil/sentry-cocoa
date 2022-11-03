#import "BuzzSentryGlobalEventProcessor.h"
#import "SentryLog.h"

@implementation BuzzSentryGlobalEventProcessor

+ (instancetype)shared
{
    static BuzzSentryGlobalEventProcessor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] initPrivate]; });
    return instance;
}

- (instancetype)initPrivate
{
    if (self = [super init]) {
        self.processors = [NSMutableArray new];
    }
    return self;
}

- (void)addEventProcessor:(BuzzSentryEventProcessor)newProcessor
{
    [self.processors addObject:newProcessor];
}

/**
 * Only for testing
 */
- (void)removeAllProcessors
{
    [self.processors removeAllObjects];
}

@end
