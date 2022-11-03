#import <Foundation/Foundation.h>

#import "BuzzSentryTransport.h"

@class BuzzSentryOptions, SentryFileManager;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TransportInitializer)
@interface BuzzSentryTransportFactory : NSObject

+ (id<BuzzSentryTransport>)initTransport:(BuzzSentryOptions *)options
                   sentryFileManager:(SentryFileManager *)sentryFileManager;

@end

NS_ASSUME_NONNULL_END
