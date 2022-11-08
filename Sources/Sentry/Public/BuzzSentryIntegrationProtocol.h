#import <Foundation/Foundation.h>

#import <BuzzSentry/BuzzSentryDefines.h>
#import <BuzzSentry/BuzzSentryOptions.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BuzzSentryIntegrationProtocol <NSObject>

/**
 * Installs the integration and returns YES if successful.
 */
- (BOOL)installWithOptions:(BuzzSentryOptions *)options;

/**
 * Uninstalls the integration.
 */
@optional
- (void)uninstall;

@end

NS_ASSUME_NONNULL_END
