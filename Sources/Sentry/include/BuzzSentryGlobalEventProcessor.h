#import "BuzzSentryDefines.h"

@class BuzzSentryEvent;

typedef BuzzSentryEvent *__nullable (^BuzzSentryEventProcessor)(BuzzSentryEvent *_Nonnull event);

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryGlobalEventProcessor : NSObject
SENTRY_NO_INIT

@property (nonatomic, strong) NSMutableArray<BuzzSentryEventProcessor> *processors;

+ (instancetype)shared;

- (void)addEventProcessor:(BuzzSentryEventProcessor)newProcessor;

@end

NS_ASSUME_NONNULL_END
