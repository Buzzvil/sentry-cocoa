#import "BuzzSentryReachability.h"
#import <XCTest/XCTest.h>

#if !TARGET_OS_WATCH
@interface SentryConnectivityTest : XCTestCase
@property (strong, nonatomic) BuzzSentryReachability *reachability;
@end

@implementation SentryConnectivityTest

- (void)setUp
{
    self.reachability = [[BuzzSentryReachability alloc] init];
}

- (void)tearDown
{
    self.reachability = nil;
}

- (void)testConnectivityRepresentations
{
    XCTAssertEqualObjects(@"none", SentryConnectivityFlagRepresentation(0));
    XCTAssertEqualObjects(
        @"none", SentryConnectivityFlagRepresentation(kSCNetworkReachabilityFlagsIsDirect));
#    if SENTRY_HAS_UIDEVICE
    // kSCNetworkReachabilityFlagsIsWWAN does not exist on macOS
    XCTAssertEqualObjects(
        @"none", SentryConnectivityFlagRepresentation(kSCNetworkReachabilityFlagsIsWWAN));
    XCTAssertEqualObjects(@"cellular",
        SentryConnectivityFlagRepresentation(
            kSCNetworkReachabilityFlagsIsWWAN | kSCNetworkReachabilityFlagsReachable));
#    endif
    XCTAssertEqualObjects(
        @"wifi", SentryConnectivityFlagRepresentation(kSCNetworkReachabilityFlagsReachable));
    XCTAssertEqualObjects(@"wifi",
        SentryConnectivityFlagRepresentation(
            kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsIsDirect));
}

- (void)testUniqueKeyForInstances
{
    BuzzSentryReachability *anotherReachability = [[BuzzSentryReachability alloc] init];
    XCTAssertNotEqualObjects(
        [self.reachability keyForInstance], [anotherReachability keyForInstance]);
    XCTAssertEqualObjects([self.reachability keyForInstance], [self.reachability keyForInstance]);
}

@end
#endif
