#import "BuzzSentryClient.h"
#import "BuzzSentryDataCategory.h"
#import "BuzzSentryDiscardReason.h"

@class BuzzSentryEnvelopeItem, SentryId, BuzzSentryAttachment, SentryThreadInspector;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const kSentryDefaultEnvironment;

@protocol BuzzSentryClientAttachmentProcessor <NSObject>

- (nullable NSArray<BuzzSentryAttachment *> *)processAttachments:
                                              (nullable NSArray<BuzzSentryAttachment *> *)attachments
                                                    forEvent:(BuzzSentryEvent *)event;

@end

@interface
BuzzSentryClient (Private)

@property (nonatomic, strong)
    NSMutableArray<id<BuzzSentryClientAttachmentProcessor>> *attachmentProcessors;
@property (nonatomic, strong) SentryThreadInspector *threadInspector;

- (SentryFileManager *)fileManager;

- (SentryId *)captureError:(NSError *)error
               withSession:(SentrySession *)session
                 withScope:(SentryScope *)scope;

- (SentryId *)captureException:(NSException *)exception
                   withSession:(SentrySession *)session
                     withScope:(SentryScope *)scope;

- (SentryId *)captureCrashEvent:(BuzzSentryEvent *)event withScope:(SentryScope *)scope;

- (SentryId *)captureCrashEvent:(BuzzSentryEvent *)event
                    withSession:(SentrySession *)session
                      withScope:(SentryScope *)scope;

- (SentryId *)captureEvent:(BuzzSentryEvent *)event
                  withScope:(SentryScope *)scope
    additionalEnvelopeItems:(NSArray<BuzzSentryEnvelopeItem *> *)additionalEnvelopeItems
    NS_SWIFT_NAME(capture(event:scope:additionalEnvelopeItems:));

/**
 * Needed by hybrid SDKs as react-native to synchronously store an envelope to disk.
 */
- (void)storeEnvelope:(BuzzSentryEnvelope *)envelope;

- (void)recordLostEvent:(BuzzSentryDataCategory)category reason:(BuzzSentryDiscardReason)reason;

- (void)addAttachmentProcessor:(id<BuzzSentryClientAttachmentProcessor>)attachmentProcessor;
- (void)removeAttachmentProcessor:(id<BuzzSentryClientAttachmentProcessor>)attachmentProcessor;

@end

NS_ASSUME_NONNULL_END
