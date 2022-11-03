#import "BuzzSentryFramesTracker.h"

NS_ASSUME_NONNULL_BEGIN

#if SENTRY_HAS_UIKIT
@interface
BuzzSentryFramesTracker (TestInit)

- (instancetype)initWithDisplayLinkWrapper:(SentryDisplayLinkWrapper *)displayLinkWrapper;

- (void)setDisplayLinkWrapper:(SentryDisplayLinkWrapper *)displayLinkWrapper;

- (void)resetFrames;

@end
#endif

NS_ASSUME_NONNULL_END
