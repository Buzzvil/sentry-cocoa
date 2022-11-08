#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface
NSData (BuzzSentryCompression)

- (NSData *_Nullable)sentry_gzippedWithCompressionLevel:(NSInteger)compressionLevel
                                                  error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
