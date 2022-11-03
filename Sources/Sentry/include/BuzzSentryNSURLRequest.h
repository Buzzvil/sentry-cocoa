#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryDsn, BuzzSentryEvent;

@interface BuzzSentryNSURLRequest : NSMutableURLRequest

- (_Nullable instancetype)initStoreRequestWithDsn:(BuzzSentryDsn *)dsn
                                         andEvent:(BuzzSentryEvent *)event
                                 didFailWithError:(NSError *_Nullable *_Nullable)error;

- (_Nullable instancetype)initStoreRequestWithDsn:(BuzzSentryDsn *)dsn
                                          andData:(NSData *)data
                                 didFailWithError:(NSError *_Nullable *_Nullable)error;

- (_Nullable instancetype)initEnvelopeRequestWithDsn:(BuzzSentryDsn *)dsn
                                             andData:(NSData *)data
                                    didFailWithError:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
