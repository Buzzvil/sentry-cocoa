#import "BuzzSentryNSURLRequest.h"
#import "NSData+SentryCompression.h"
#import "BuzzSentryClient.h"
#import "BuzzSentryDsn.h"
#import "SentryError.h"
#import "BuzzSentryEvent.h"
#import "BuzzSentryHub.h"
#import "SentryLog.h"
#import "BuzzSentryMeta.h"
#import "BuzzSentrySDK+Private.h"
#import "SentrySerialization.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const SentryServerVersionString = @"7";
NSTimeInterval const SentryRequestTimeout = 15;

@interface
BuzzSentryNSURLRequest ()

@property (nonatomic, strong) BuzzSentryDsn *dsn;

@end

@implementation BuzzSentryNSURLRequest

- (_Nullable instancetype)initStoreRequestWithDsn:(BuzzSentryDsn *)dsn
                                         andEvent:(BuzzSentryEvent *)event
                                 didFailWithError:(NSError *_Nullable *_Nullable)error
{
    NSDictionary *serialized = [event serialize];
    NSData *jsonData = [SentrySerialization dataWithJSONObject:serialized error:error];
    if (nil == jsonData) {
        if (error) {
            // TODO: We're possibly overriding an error set by the actual
            // code that failed ^
            *error = NSErrorFromSentryError(
                kSentryErrorJsonConversionError, @"Event cannot be converted to JSON");
        }
        return nil;
    }

    if ([BuzzSentrySDK.currentHub getClient].options.debug == YES) {
        SENTRY_LOG_DEBUG(@"Sending JSON -------------------------------");
        SENTRY_LOG_DEBUG(
            @"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
        SENTRY_LOG_DEBUG(@"--------------------------------------------");
    }
    return [self initStoreRequestWithDsn:dsn andData:jsonData didFailWithError:error];
}

- (_Nullable instancetype)initStoreRequestWithDsn:(BuzzSentryDsn *)dsn
                                          andData:(NSData *)data
                                 didFailWithError:(NSError *_Nullable *_Nullable)error
{
    NSURL *apiURL = [dsn getStoreEndpoint];
    self = [super initWithURL:apiURL
                  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
              timeoutInterval:SentryRequestTimeout];
    if (self) {
        NSString *authHeader = newAuthHeader(dsn.url);

        self.HTTPMethod = @"POST";
        [self setValue:authHeader forHTTPHeaderField:@"X-Sentry-Auth"];
        [self setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [self setValue:BuzzSentryMeta.sdkName forHTTPHeaderField:@"User-Agent"];
        [self setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        self.HTTPBody = [data sentry_gzippedWithCompressionLevel:-1 error:error];
    }
    return self;
}

// TODO: Get refactored out to be a single init method
- (_Nullable instancetype)initEnvelopeRequestWithDsn:(BuzzSentryDsn *)dsn
                                             andData:(NSData *)data
                                    didFailWithError:(NSError *_Nullable *_Nullable)error
{
    NSURL *apiURL = [dsn getEnvelopeEndpoint];
    self = [super initWithURL:apiURL
                  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
              timeoutInterval:SentryRequestTimeout];
    if (self) {
        NSString *authHeader = newAuthHeader(dsn.url);

        self.HTTPMethod = @"POST";
        [self setValue:authHeader forHTTPHeaderField:@"X-Sentry-Auth"];
        [self setValue:@"application/x-sentry-envelope" forHTTPHeaderField:@"Content-Type"];
        [self setValue:BuzzSentryMeta.sdkName forHTTPHeaderField:@"User-Agent"];
        [self setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        self.HTTPBody = [data sentry_gzippedWithCompressionLevel:-1 error:error];
    }

    return self;
}

static NSString *
newHeaderPart(NSString *key, id value)
{
    return [NSString stringWithFormat:@"%@=%@", key, value];
}

static NSString *
newAuthHeader(NSURL *url)
{
    NSMutableString *string = [NSMutableString stringWithString:@"Sentry "];
    [string appendFormat:@"%@,", newHeaderPart(@"sentry_version", SentryServerVersionString)];
    [string
        appendFormat:@"%@,",
        newHeaderPart(@"sentry_client",
            [NSString stringWithFormat:@"%@/%@", BuzzSentryMeta.sdkName, BuzzSentryMeta.versionString])];
    [string
        appendFormat:@"%@,",
        newHeaderPart(@"sentry_timestamp", @((NSInteger)[[NSDate date] timeIntervalSince1970]))];
    [string appendFormat:@"%@", newHeaderPart(@"sentry_key", url.user)];
    if (nil != url.password) {
        [string appendFormat:@",%@", newHeaderPart(@"sentry_secret", url.password)];
    }
    return string;
}

@end

NS_ASSUME_NONNULL_END
