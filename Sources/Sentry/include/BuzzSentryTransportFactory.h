#import <Foundation/Foundation.h>

#import "BuzzSentryTransport.h"

@class BuzzSentryOptions, BuzzSentryFileManager;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TransportInitializer)
@interface BuzzSentryTransportFactory : NSObject

+ (id<BuzzSentryTransport>)initTransport:(BuzzSentryOptions *)options
                   BuzzSentryFileManager:(BuzzSentryFileManager *)BuzzSentryFileManager;

@end

NS_ASSUME_NONNULL_END
