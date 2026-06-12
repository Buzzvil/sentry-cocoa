#import "BuzzSentryCrashDynamicLinker.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
  A wrapper around BuzzSentryCrash for testability.
 */
@protocol BuzzSentryCrashBinaryImageProvider <NSObject>

- (NSInteger)getImageCount;

- (BuzzSentryCrashBinaryImage)getBinaryImage:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
