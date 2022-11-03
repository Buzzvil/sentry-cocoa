#import <Foundation/Foundation.h>

#import "SentryTransport.h"

@class BuzzSentryOptions, SentryFileManager;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TransportInitializer)
@interface SentryTransportFactory : NSObject

+ (id<SentryTransport>)initTransport:(BuzzSentryOptions *)options
                   sentryFileManager:(SentryFileManager *)sentryFileManager;

@end

NS_ASSUME_NONNULL_END
