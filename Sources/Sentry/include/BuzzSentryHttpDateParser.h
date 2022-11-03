#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Parses a string in the format of http date to NSDate. For more details see:
 * https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date.
 * BuzzSentryHttpDateParser is thread safe.
 */
NS_SWIFT_NAME(HttpDateParser)
@interface BuzzSentryHttpDateParser : NSObject

- (NSDate *_Nullable)dateFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
