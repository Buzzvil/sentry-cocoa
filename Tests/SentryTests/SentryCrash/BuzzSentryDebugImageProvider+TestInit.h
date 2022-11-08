#import "BuzzSentryDebugImageProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryDebugImageProvider (TestInit)
- (instancetype)initWithBinaryImageProvider:(id<BuzzSentryCrashBinaryImageProvider>)binaryImageProvider;

@end

NS_ASSUME_NONNULL_END
