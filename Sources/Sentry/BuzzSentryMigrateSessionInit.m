#import "BuzzSentryMigrateSessionInit.h"
#import "BuzzSentryEnvelope.h"
#import "BuzzSentryEnvelopeItemType.h"
#import "BuzzSentryLog.h"
#import "BuzzSentrySerialization.h"
#import "BuzzSentrySession+Private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BuzzSentryMigrateSessionInit

+ (BOOL)migrateSessionInit:(BuzzSentryEnvelope *)envelope
          envelopesDirPath:(NSString *)envelopesDirPath
         envelopeFilePaths:(NSArray<NSString *> *)envelopeFilePaths;
{
    if (nil == envelope) {
        return NO;
    }

    for (BuzzSentryEnvelopeItem *item in envelope.items) {
        if ([item.header.type isEqualToString:BuzzSentryEnvelopeItemTypeSession]) {
            BuzzSentrySession *session = [BuzzSentrySerialization sessionWithData:item.data];
            if (nil != session && [session.flagInit boolValue]) {
                BOOL didSetInitFlag =
                    [self setInitFlagOnNextEnvelopeWithSameSessionId:session
                                                    envelopesDirPath:envelopesDirPath
                                                   envelopeFilePaths:envelopeFilePaths];

                if (didSetInitFlag) {
                    return YES;
                }
            }
        }
    }

    return NO;
}

+ (BOOL)setInitFlagOnNextEnvelopeWithSameSessionId:(BuzzSentrySession *)session
                                  envelopesDirPath:(NSString *)envelopesDirPath
                                 envelopeFilePaths:(NSArray<NSString *> *)envelopeFilePaths
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    for (NSString *envelopeFilePath in envelopeFilePaths) {
        NSString *envelopePath = [envelopesDirPath stringByAppendingPathComponent:envelopeFilePath];
        NSData *envelopeData = [fileManager contentsAtPath:envelopePath];

        // Some error occurred while getting the envelopeData
        if (nil == envelopeData) {
            continue;
        }

        BuzzSentryEnvelope *envelope = [BuzzSentrySerialization envelopeWithData:envelopeData];

        if (nil != envelope) {
            BOOL didSetInitFlag = [self setInitFlagIfContainsSameSessionId:session.sessionId
                                                                  envelope:envelope
                                                          envelopeFilePath:envelopePath];

            if (didSetInitFlag) {
                return YES;
            }
        }
    }

    return NO;
}

+ (BOOL)setInitFlagIfContainsSameSessionId:(NSUUID *)sessionId
                                  envelope:(BuzzSentryEnvelope *)envelope
                          envelopeFilePath:(NSString *)envelopeFilePath
{
    for (BuzzSentryEnvelopeItem *item in envelope.items) {
        if ([item.header.type isEqualToString:BuzzSentryEnvelopeItemTypeSession]) {
            BuzzSentrySession *localSession = [BuzzSentrySerialization sessionWithData:item.data];

            if (nil != localSession && [localSession.sessionId isEqual:sessionId]) {
                [localSession setFlagInit];

                [self storeSessionInit:envelope session:localSession path:envelopeFilePath];
                return YES;
            }
        }
    }

    return NO;
}

+ (void)storeSessionInit:(BuzzSentryEnvelope *)originalEnvelope
                 session:(BuzzSentrySession *)session
                    path:(NSString *)envelopeFilePath
{
    NSArray<BuzzSentryEnvelopeItem *> *envelopeItemsWithUpdatedSession =
        [self replaceSessionEnvelopeItem:session onEnvelope:originalEnvelope];
    BuzzSentryEnvelope *envelopeWithInitFlag =
        [[BuzzSentryEnvelope alloc] initWithHeader:originalEnvelope.header
                                         items:envelopeItemsWithUpdatedSession];

    NSError *error;
    NSData *envelopeWithInitFlagData = [BuzzSentrySerialization dataWithEnvelope:envelopeWithInitFlag
                                                                       error:&error];
    [envelopeWithInitFlagData writeToFile:envelopeFilePath
                                  options:NSDataWritingAtomic
                                    error:&error];

    if (nil != error) {
        [BuzzSentryLog
            logWithMessage:[NSString stringWithFormat:@"Could not migrate session init, because "
                                                      @"storing the updated envelope failed: %@",
                                     error.description]
                  andLevel:kSentryLevelError];
    }
}

+ (NSArray<BuzzSentryEnvelopeItem *> *)replaceSessionEnvelopeItem:(BuzzSentrySession *)session
                                                   onEnvelope:(BuzzSentryEnvelope *)envelope
{
    NSPredicate *noSessionEnvelopeItems =
        [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            BuzzSentryEnvelopeItem *item = object;
            return ![item.header.type isEqualToString:BuzzSentryEnvelopeItemTypeSession];
        }];
    NSMutableArray<BuzzSentryEnvelopeItem *> *itemsWithoutSession
        = (NSMutableArray<BuzzSentryEnvelopeItem *> *)[[envelope.items
            filteredArrayUsingPredicate:noSessionEnvelopeItems] mutableCopy];

    BuzzSentryEnvelopeItem *sessionEnvelopeItem = [[BuzzSentryEnvelopeItem alloc] initWithSession:session];
    [itemsWithoutSession addObject:sessionEnvelopeItem];
    return itemsWithoutSession;
}

@end

NS_ASSUME_NONNULL_END
