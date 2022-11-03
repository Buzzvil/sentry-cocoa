#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryDsn, SentryEvent;

@interface BuzzSentryNSURLRequest : NSMutableURLRequest

- (_Nullable instancetype)initStoreRequestWithDsn:(BuzzSentryDsn *)dsn
                                         andEvent:(SentryEvent *)event
                                 didFailWithError:(NSError *_Nullable *_Nullable)error;

- (_Nullable instancetype)initStoreRequestWithDsn:(BuzzSentryDsn *)dsn
                                          andData:(NSData *)data
                                 didFailWithError:(NSError *_Nullable *_Nullable)error;

- (_Nullable instancetype)initEnvelopeRequestWithDsn:(BuzzSentryDsn *)dsn
                                             andData:(NSData *)data
                                    didFailWithError:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
