#import "TestNSURLRequestBuilder.h"

NS_ASSUME_NONNULL_BEGIN

@interface
TestNSURLRequestBuilder ()

@property (nonatomic, strong) BuzzSentryNSURLRequestBuilder *builder;
@property (nonatomic, strong) NSError *error;

@end

@implementation TestNSURLRequestBuilder

- (instancetype)init
{
    if (self = [super init]) {
        self.builder = [[BuzzSentryNSURLRequestBuilder alloc] init];
    }
    return self;
}

- (NSURLRequest *)createEnvelopeRequest:(BuzzSentryEnvelope *)envelope
                                    dsn:(BuzzSentryDsn *)dsn
                       didFailWithError:(NSError *_Nullable *_Nullable)error
{
    NSURLRequest *request = [self.builder createEnvelopeRequest:envelope
                                                            dsn:dsn
                                               didFailWithError:error];
    if (self.shouldFailWithError) {
        self.error = [[NSError alloc] initWithDomain:@"TestErrorDomain" code:12 userInfo:nil];
        *error = self.error;
    }
    return request;
}

@end

NS_ASSUME_NONNULL_END
