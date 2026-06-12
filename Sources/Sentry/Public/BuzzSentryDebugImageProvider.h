#import <BuzzSentry/BuzzSentryDefines.h>
#import <Foundation/Foundation.h>

@class BuzzSentryDebugMeta, BuzzSentryThread;

NS_ASSUME_NONNULL_BEGIN

/**
 * Reserved for hybrid SDKs that the debug image list for symbolication.
 */
@interface BuzzSentryDebugImageProvider : NSObject

- (instancetype)init;

/**
 * Returns a list of debug images that are being referenced in the given threads.
 *
 * @param threads A list of BuzzSentryThread that may or may not contains a stacktrace.
 */
- (NSArray<BuzzSentryDebugMeta *> *)getDebugImagesForThreads:(NSArray<BuzzSentryThread *> *)threads;

/**
 * Returns the current list of debug images. Be aware that the BuzzSentryDebugMeta is actually
 * describing a debug image. This class should be renamed to SentryDebugImage in a future version.
 */
- (NSArray<BuzzSentryDebugMeta *> *)getDebugImages;

@end

NS_ASSUME_NONNULL_END
