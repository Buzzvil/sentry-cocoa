#import "BuzzSentryDsn.h"
#import "BuzzSentryError.h"
#import "BuzzSentryMeta.h"
#import "BuzzSentryNSURLRequest.h"
#import <Sentry/Sentry.h>
#import <XCTest/XCTest.h>

@interface BuzzSentryDsnTests : XCTestCase

@end

@implementation BuzzSentryDsnTests

- (void)testMissingUsernamePassword
{
    NSError *error = nil;
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] initWithDict:@{ @"dsn" : @"https://sentry.io" }
                                                didFailWithError:&error];
    XCTAssertEqual(kBuzzSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(options);
}

- (void)testDsnHeaderUsernameAndPassword
{
    NSError *error = nil;
    BuzzSentryDsn *dsn = [[BuzzSentryDsn alloc] initWithString:@"https://username:password@sentry.io/1"
                                      didFailWithError:&error];
    BuzzSentryNSURLRequest *request = [[BuzzSentryNSURLRequest alloc] initStoreRequestWithDsn:dsn
                                                                              andData:[NSData data]
                                                                     didFailWithError:&error];

    NSString *authHeader = [[NSString alloc]
        initWithFormat:@"Sentry "
                       @"sentry_version=7,sentry_client=sentry.cocoa/"
                       @"%@,sentry_timestamp=%@,sentry_key=username,sentry_"
                       @"secret=password",
        BuzzSentryMeta.versionString, @((NSInteger)[[NSDate date] timeIntervalSince1970])];

    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"X-Sentry-Auth"], authHeader);
    XCTAssertNil(error);
}

- (void)testDsnHeaderUsername
{
    NSError *error = nil;
    BuzzSentryDsn *dsn = [[BuzzSentryDsn alloc] initWithString:@"https://username@sentry.io/1"
                                      didFailWithError:&error];
    BuzzSentryNSURLRequest *request = [[BuzzSentryNSURLRequest alloc] initStoreRequestWithDsn:dsn
                                                                              andData:[NSData data]
                                                                     didFailWithError:&error];

    NSString *authHeader = [[NSString alloc]
        initWithFormat:@"Sentry "
                       @"sentry_version=7,sentry_client=sentry.cocoa/"
                       @"%@,sentry_timestamp=%@,sentry_key=username",
        BuzzSentryMeta.versionString, @((NSInteger)[[NSDate date] timeIntervalSince1970])];

    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"X-Sentry-Auth"], authHeader);
    XCTAssertNil(error);
}

- (void)testMissingScheme
{
    NSError *error = nil;
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] initWithDict:@{ @"dsn" : @"sentry.io" }
                                                didFailWithError:&error];
    XCTAssertEqual(kBuzzSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(options);
}

- (void)testMissingHost
{
    NSError *error = nil;
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] initWithDict:@{ @"dsn" : @"http:///1" }
                                                didFailWithError:&error];
    XCTAssertEqual(kBuzzSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(options);
}

- (void)testUnsupportedProtocol
{
    NSError *error = nil;
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc] initWithDict:@{ @"dsn" : @"ftp://sentry.io/1" }
                                                didFailWithError:&error];
    XCTAssertEqual(kBuzzSentryErrorInvalidDsnError, error.code);
    XCTAssertNil(options);
}

- (void)testDsnUrl
{
    NSError *error = nil;
    BuzzSentryDsn *dsn = [[BuzzSentryDsn alloc] initWithString:@"https://username:password@getsentry.net/1"
                                      didFailWithError:&error];

    XCTAssertEqualObjects(
        [[dsn getStoreEndpoint] absoluteString], @"https://getsentry.net/api/1/store/");
    XCTAssertNil(error);

    BuzzSentryDsn *dsn2 =
        [[BuzzSentryDsn alloc] initWithString:@"https://username:password@sentry.io/foo/bar/baz/1"
                         didFailWithError:&error];

    XCTAssertEqualObjects(
        [[dsn2 getStoreEndpoint] absoluteString], @"https://sentry.io/foo/bar/baz/api/1/store/");
    XCTAssertNil(error);
}

- (void)testGetEnvelopeUrl
{
    NSError *error = nil;
    BuzzSentryDsn *dsn = [[BuzzSentryDsn alloc] initWithString:@"https://username:password@getsentry.net/1"
                                      didFailWithError:&error];

    XCTAssertEqualObjects(
        [[dsn getEnvelopeEndpoint] absoluteString], @"https://getsentry.net/api/1/envelope/");
    XCTAssertNil(error);

    BuzzSentryDsn *dsn2 =
        [[BuzzSentryDsn alloc] initWithString:@"https://username:password@sentry.io/foo/bar/baz/1"
                         didFailWithError:&error];

    XCTAssertEqualObjects([[dsn2 getEnvelopeEndpoint] absoluteString],
        @"https://sentry.io/foo/bar/baz/api/1/envelope/");
    XCTAssertNil(error);
}

- (void)testGetStoreDsnCachesResult
{
    BuzzSentryDsn *dsn = [[BuzzSentryDsn alloc] initWithString:@"https://username:password@getsentry.net/1"
                                      didFailWithError:nil];

    XCTAssertNotNil([dsn getStoreEndpoint]);
    // Assert same reference
    XCTAssertTrue([dsn getStoreEndpoint] == [dsn getStoreEndpoint]);
}

- (void)testGetEnvelopeDsnCachesResult
{
    BuzzSentryDsn *dsn = [[BuzzSentryDsn alloc] initWithString:@"https://username:password@getsentry.net/1"
                                      didFailWithError:nil];

    XCTAssertNotNil([dsn getEnvelopeEndpoint]);
    // Assert same reference
    XCTAssertTrue([dsn getEnvelopeEndpoint] == [dsn getEnvelopeEndpoint]);
}

@end
