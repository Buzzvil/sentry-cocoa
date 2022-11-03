#import "BuzzSentryFileManager.h"
#import <Sentry/BuzzSentry.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Used to make properties visible for testing.
 */
@interface
BuzzSentryFileManager (TestProperties)

@property (nonatomic, copy) NSString *eventsPath;

@property (nonatomic, copy) NSString *envelopesPath;

@property (nonatomic, copy) NSString *timezoneOffsetFilePath;

@end

NS_ASSUME_NONNULL_END
