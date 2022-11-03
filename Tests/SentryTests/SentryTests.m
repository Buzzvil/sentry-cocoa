#import "NSDate+SentryExtras.h"
#import "BuzzSentryBreadcrumbTracker.h"
#import "SentryLevelMapper.h"
#import "BuzzSentryMessage.h"
#import "BuzzSentryMeta.h"
#import "BuzzSentrySDK+Private.h"
#import <Sentry/Sentry.h>
#import <XCTest/XCTest.h>

#import "BuzzSentryDataCategory.h"

@interface
BuzzSentryBreadcrumbTracker (Private)

+ (NSString *)sanitizeViewControllerName:(NSString *)controller;

@end

@interface SentryTests : XCTestCase

@end

@implementation SentryTests

- (void)setUp
{
    [BuzzSentrySDK.currentHub bindClient:nil];
}

- (void)testVersion
{
    NSDictionary *info = [[NSBundle bundleForClass:[BuzzSentryClient class]] infoDictionary];
    NSString *version = [NSString stringWithFormat:@"%@", info[@"CFBundleShortVersionString"]];
    if ([info[@"CFBundleIdentifier"] isEqualToString:@"io.sentry.Sentry"]) {
        // This test is running on a bundle that is not the SDK
        // (code was loaded inside an app for example)
        // in this case, we don't care about asserting our hard coded value matches
        // since this will be the app version instead of our SDK version.
        XCTAssert([version isEqualToString:BuzzSentryMeta.versionString],
            @"Version of bundle:%@ not equal to version of BuzzSentryMeta:%@", version,
            BuzzSentryMeta.versionString);
    }
}

- (void)testSharedClient
{
    NSError *error = nil;
    BuzzSentryOptions *options = [[BuzzSentryOptions alloc]
            initWithDict:@{ @"dsn" : @"https://username:password@app.getsentry.com/12345" }
        didFailWithError:&error];

    BuzzSentryClient *client = [[BuzzSentryClient alloc] initWithOptions:options];
    XCTAssertNil(error);
    XCTAssertNil([BuzzSentrySDK.currentHub getClient]);
    [BuzzSentrySDK.currentHub bindClient:client];
    XCTAssertNotNil([BuzzSentrySDK.currentHub getClient]);
    [BuzzSentrySDK.currentHub bindClient:nil];
}

- (void)testSDKDefaultHub
{
    [BuzzSentrySDK startWithOptions:@{ @"dsn" : @"https://username:password@app.getsentry.com/12345" }];
    XCTAssertNotNil([BuzzSentrySDK.currentHub getClient]);
    [BuzzSentrySDK.currentHub bindClient:nil];
}

- (void)testSDKBreadCrumbAdd
{
    [BuzzSentrySDK startWithOptions:@{ @"dsn" : @"https://username:password@app.getsentry.com/12345" }];

    BuzzSentryBreadcrumb *crumb = [[BuzzSentryBreadcrumb alloc] initWithLevel:kSentryLevelInfo
                                                             category:@"testCategory"];
    crumb.type = @"testType";
    crumb.message = @"testMessage";
    crumb.data = @{ @"testDataKey" : @"testDataVaue" };

    [BuzzSentrySDK addBreadcrumb:crumb];
}

- (void)testSDKCaptureEvent
{
    [BuzzSentrySDK startWithOptions:@{ @"dsn" : @"https://username:password@app.getsentry.com/12345" }];

    BuzzSentryEvent *event = [[BuzzSentryEvent alloc] initWithLevel:kSentryLevelFatal];

    event.timestamp = [NSDate date];
    event.message = [[BuzzSentryMessage alloc] initWithFormatted:@"testy test"];

    [BuzzSentrySDK captureEvent:event];
}

- (void)testSDKCaptureError
{
    [BuzzSentrySDK startWithOptions:@{ @"dsn" : @"https://username:password@app.getsentry.com/12345" }];

    NSError *error =
        [NSError errorWithDomain:@"testworld"
                            code:200
                        userInfo:@{ NSLocalizedDescriptionKey : @"test ran out of money" }];
    [BuzzSentrySDK captureError:error];
}

- (void)testLevelNames
{
    XCTAssertEqual(kSentryLevelNone, sentryLevelForString(kSentryLevelNameNone));
    XCTAssertEqual(kSentryLevelDebug, sentryLevelForString(kSentryLevelNameDebug));
    XCTAssertEqual(kSentryLevelInfo, sentryLevelForString(kSentryLevelNameInfo));
    XCTAssertEqual(kSentryLevelWarning, sentryLevelForString(kSentryLevelNameWarning));
    XCTAssertEqual(kSentryLevelError, sentryLevelForString(kSentryLevelNameError));
    XCTAssertEqual(kSentryLevelFatal, sentryLevelForString(kSentryLevelNameFatal));

    XCTAssertEqual(kSentryLevelError, sentryLevelForString(@"fdjsafdsa"),
        @"Failed to map an unexpected string value to the default case.");

    XCTAssertEqualObjects(kSentryLevelNameNone, nameForSentryLevel(kSentryLevelNone));
    XCTAssertEqualObjects(kSentryLevelNameDebug, nameForSentryLevel(kSentryLevelDebug));
    XCTAssertEqualObjects(kSentryLevelNameInfo, nameForSentryLevel(kSentryLevelInfo));
    XCTAssertEqualObjects(kSentryLevelNameWarning, nameForSentryLevel(kSentryLevelWarning));
    XCTAssertEqualObjects(kSentryLevelNameError, nameForSentryLevel(kSentryLevelError));
    XCTAssertEqualObjects(kSentryLevelNameFatal, nameForSentryLevel(kSentryLevelFatal));
}

- (void)testLevelOrder
{
    XCTAssertGreaterThan(kSentryLevelFatal, kSentryLevelError);
    XCTAssertGreaterThan(kSentryLevelError, kSentryLevelWarning);
    XCTAssertGreaterThan(kSentryLevelWarning, kSentryLevelInfo);
    XCTAssertGreaterThan(kSentryLevelInfo, kSentryLevelDebug);
    XCTAssertGreaterThan(kSentryLevelDebug, kSentryLevelNone);
}

- (void)testDateCategory
{
    NSTimeInterval timeInterval = 1605888590.123;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    XCTAssertEqual(
        [[NSDate sentry_fromIso8601String:[date sentry_toIso8601String]] timeIntervalSince1970],
        timeInterval);
}

- (void)testDateCategoryPrecision
{
    NSDate *date1 = [NSDate dateWithTimeIntervalSinceReferenceDate:0.1234];
    XCTAssertEqualObjects([date1 sentry_toIso8601String], @"2001-01-01T00:00:00.123Z");

    NSDate *date2 = [NSDate dateWithTimeIntervalSinceReferenceDate:0.9995];
    XCTAssertEqualObjects([date2 sentry_toIso8601String], @"2001-01-01T00:00:01.000Z");
}

- (void)testDateCategoryCompactibility
{
    NSDate *date = [NSDate sentry_fromIso8601String:@"2020-02-27T11:35:26Z"];
    XCTAssertEqual([date timeIntervalSince1970], 1582803326.0);
}

@end
