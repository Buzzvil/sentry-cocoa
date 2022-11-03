#import "BuzzSentrySerialization.h"
#import <Sentry/BuzzSentry.h>
#import <XCTest/XCTest.h>

@interface BuzzSentrySerializationNilTests : XCTestCase

@end

/**
 * Actual tests are written in BuzzSentrySerializationTests.swift. This class only exists to test
 * passing nil values, which is not possible with Swift cause the compiler avoids it.
 */
@implementation BuzzSentrySerializationNilTests

- (void)testBuzzSentryEnvelopeSerializerWithNilInput
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertNil([BuzzSentrySerialization envelopeWithData:nil]);
#pragma clang diagnostic pop
}

@end
