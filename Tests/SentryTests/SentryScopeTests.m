#import "BuzzSentryBreadcrumb.h"
#import "BuzzSentryClient+Private.h"
#import "BuzzSentryScope+Private.h"
#import "BuzzSentryScope.h"
#import "BuzzSentryUser.h"
#import <XCTest/XCTest.h>

@interface BuzzSentryScopeTests : XCTestCase

@end

@implementation BuzzSentryScopeTests

- (BuzzSentryBreadcrumb *)getBreadcrumb
{
    return [[BuzzSentryBreadcrumb alloc] initWithLevel:kSentryLevelDebug category:@"http"];
}

- (void)testSetExtra
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    [scope setExtras:@{ @"c" : @"d" }];
    XCTAssertEqualObjects([[scope serialize] objectForKey:@"extra"], @{ @"c" : @"d" });
}

- (void)testRemoveExtra
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    [scope setExtraValue:@1 forKey:@"A"];
    [scope setExtraValue:@2 forKey:@"B"];
    [scope setExtraValue:@3 forKey:@"C"];

    [scope removeExtraForKey:@"A"];
    [scope setExtraValue:nil forKey:@"C"];

    NSDictionary<NSString *, NSString *> *actual = scope.serialize[@"extra"];
    XCTAssertTrue([@{ @"B" : @2 } isEqualToDictionary:actual]);
}

- (void)testBreadcrumbOlderReplacedByNewer
{
    NSUInteger expectedMaxBreadcrumb = 1;
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] initWithMaxBreadcrumbs:expectedMaxBreadcrumb];
    BuzzSentryBreadcrumb *crumb1 = [[BuzzSentryBreadcrumb alloc] init];
    [crumb1 setMessage:@"crumb 1"];
    [scope addBreadcrumb:crumb1];
    NSDictionary<NSString *, id> *scope1 = [scope serialize];
    NSArray *scope1Crumbs = [scope1 objectForKey:@"breadcrumbs"];
    XCTAssertEqual(expectedMaxBreadcrumb, [scope1Crumbs count]);

    BuzzSentryBreadcrumb *crumb2 = [[BuzzSentryBreadcrumb alloc] init];
    [crumb2 setMessage:@"crumb 2"];
    [scope addBreadcrumb:crumb2];
    NSDictionary<NSString *, id> *scope2 = [scope serialize];
    NSArray *scope2Crumbs = [scope2 objectForKey:@"breadcrumbs"];
    XCTAssertEqual(expectedMaxBreadcrumb, [scope2Crumbs count]);
}

- (void)testDefaultMaxCapacity
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    for (int i = 0; i < 2000; ++i) {
        [scope addBreadcrumb:[[BuzzSentryBreadcrumb alloc] init]];
    }

    NSDictionary<NSString *, id> *scopeSerialized = [scope serialize];
    NSArray *scopeCrumbs = [scopeSerialized objectForKey:@"breadcrumbs"];
    XCTAssertEqual(100, [scopeCrumbs count]);
}

- (void)testSetTagValueForKey
{
    NSDictionary<NSString *, NSString *> *excpected = @{ @"A" : @"1", @"B" : @"2", @"C" : @"" };

    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    [scope setTagValue:@"1" forKey:@"A"];
    [scope setTagValue:@"overwriteme" forKey:@"B"];
    [scope setTagValue:@"2" forKey:@"B"];
    [scope setTagValue:@"" forKey:@"C"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [scope setTagValue:nil forKey:@"D"];
#pragma clang diagnostic pop

    NSDictionary<NSString *, NSString *> *actual = scope.serialize[@"tags"];
    XCTAssertTrue([excpected isEqualToDictionary:actual]);
}

- (void)testRemoveTag
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    [scope setTagValue:@"1" forKey:@"A"];
    [scope setTagValue:@"2" forKey:@"B"];

    [scope removeTagForKey:@"A"];

    NSDictionary<NSString *, NSString *> *actual = scope.serialize[@"tags"];
    XCTAssertTrue([@{ @"B" : @"2" } isEqualToDictionary:actual]);
}

- (void)testSetUser
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    BuzzSentryUser *user = [[BuzzSentryUser alloc] init];

    [user setUserId:@"123"];
    [scope setUser:user];

    NSDictionary<NSString *, id> *scopeSerialized = [scope serialize];
    NSDictionary<NSString *, id> *scopeUser = [scopeSerialized objectForKey:@"user"];
    NSString *scopeUserId = [scopeUser objectForKey:@"id"];

    XCTAssertEqualObjects(scopeUserId, @"123");
}

- (void)testSetContextValueForKey
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    [scope setContextValue:@{ @"AA" : @1 } forKey:@"A"];
    [scope setContextValue:@{ @"BB" : @"2" } forKey:@"B"];

    NSDictionary *actual = scope.serialize[@"context"];
    NSDictionary *expected = @{ @"A" : @ { @"AA" : @1 }, @"B" : @ { @"BB" : @"2" } };
    XCTAssertTrue([expected isEqualToDictionary:actual]);
}

- (void)testRemoveContextForKey
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    [scope setContextValue:@{ @"AA" : @1 } forKey:@"A"];
    [scope setContextValue:@{ @"BB" : @"2" } forKey:@"B"];

    [scope removeContextForKey:@"B"];

    NSDictionary *actual = scope.serialize[@"context"];
    NSDictionary *expected = @{ @"A" : @ { @"AA" : @1 } };
    XCTAssertTrue([expected isEqualToDictionary:actual]);
}

- (void)testDistSerializes
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    NSString *expectedDist = @"dist-1.0";
    [scope setDist:expectedDist];
    XCTAssertEqualObjects([[scope serialize] objectForKey:@"dist"], expectedDist);
}

- (void)testEnvironmentSerializes
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    NSString *expectedEnvironment = kSentryDefaultEnvironment;
    [scope setEnvironment:expectedEnvironment];
    XCTAssertEqualObjects([[scope serialize] objectForKey:@"environment"], expectedEnvironment);
}

- (void)testClearBreadcrumb
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    [scope clearBreadcrumbs];
    [scope addBreadcrumb:[self getBreadcrumb]];
    [scope clearBreadcrumbs];
    XCTAssertTrue([[[scope serialize] objectForKey:@"breadcrumbs"] count] == 0);
}

- (void)testInitWithScope
{
    BuzzSentryScope *scope = [[BuzzSentryScope alloc] init];
    [scope setExtras:@{ @"a" : @"b" }];
    [scope setTags:@{ @"b" : @"c" }];
    [scope addBreadcrumb:[self getBreadcrumb]];
    [scope setUser:[[BuzzSentryUser alloc] initWithUserId:@"id"]];
    [scope setContextValue:@{ @"e" : @"f" } forKey:@"myContext"];
    [scope setDist:@"456"];
    [scope setEnvironment:@"789"];
    [scope setFingerprint:@[ @"a" ]];

    NSMutableDictionary *snapshot = [scope serialize].mutableCopy;

    BuzzSentryScope *cloned = [[BuzzSentryScope alloc] initWithScope:scope];
    XCTAssertEqualObjects(snapshot, [cloned serialize]);

    [cloned setExtras:@{ @"aa" : @"b" }];
    [cloned setTags:@{ @"ab" : @"c" }];
    [cloned addBreadcrumb:[[BuzzSentryBreadcrumb alloc] initWithLevel:kSentryLevelDebug
                                                         category:@"http2"]];
    [cloned setUser:[[BuzzSentryUser alloc] initWithUserId:@"aid"]];
    [cloned setContextValue:@{ @"ae" : @"af" } forKey:@"myContext"];
    [cloned setDist:@"a456"];
    [cloned setEnvironment:@"a789"];

    XCTAssertEqualObjects(snapshot, [scope serialize]);
    XCTAssertNotEqualObjects([scope serialize], [cloned serialize]);
}

@end
