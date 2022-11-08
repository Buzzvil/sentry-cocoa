#import "BuzzSentryMigrateSessionInit.h"
#import "BuzzSentrySerialization.h"
#import <XCTest/XCTest.h>

/**
 * Most of the tests are in BuzzSentryFileManagerTests.
 */
@interface BuzzSentryMigrateSessionInitTests : XCTestCase

@end

@implementation BuzzSentryMigrateSessionInitTests

- (void)testWithGarbageParametersDoesNotCrash
{
    BuzzSentryEnvelope *envelope = [BuzzSentrySerialization envelopeWithData:[[NSData alloc] init]];
    [BuzzSentryMigrateSessionInit migrateSessionInit:envelope
                                envelopesDirPath:@"asdf"
                               envelopeFilePaths:@[]];
}

@end
