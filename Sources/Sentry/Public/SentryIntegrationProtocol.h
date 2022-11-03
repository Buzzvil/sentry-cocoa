#import <Foundation/Foundation.h>

#import "SentryDefines.h"
#import "BuzzSentryOptions.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SentryIntegrationProtocol <NSObject>

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
