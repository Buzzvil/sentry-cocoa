#import "BuzzSentryClient.h"
#import "SentryDataCategory.h"
#import "SentryDiscardReason.h"

@class BuzzSentryEnvelopeItem, SentryId, BuzzSentryAttachment, SentryThreadInspector;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const kSentryDefaultEnvironment;

@protocol BuzzSentryClientAttachmentProcessor <NSObject>

- (nullable NSArray<BuzzSentryAttachment *> *)processAttachments:
                                              (nullable NSArray<BuzzSentryAttachment *> *)attachments
                                                    forEvent:(SentryEvent *)event;

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

- (SentryId *)captureCrashEvent:(SentryEvent *)event withScope:(SentryScope *)scope;

- (SentryId *)captureCrashEvent:(SentryEvent *)event
                    withSession:(SentrySession *)session
                      withScope:(SentryScope *)scope;

- (SentryId *)captureEvent:(SentryEvent *)event
                  withScope:(SentryScope *)scope
    additionalEnvelopeItems:(NSArray<BuzzSentryEnvelopeItem *> *)additionalEnvelopeItems
    NS_SWIFT_NAME(capture(event:scope:additionalEnvelopeItems:));

/**
 * Needed by hybrid SDKs as react-native to synchronously store an envelope to disk.
 */
- (void)storeEnvelope:(BuzzSentryEnvelope *)envelope;

- (void)recordLostEvent:(SentryDataCategory)category reason:(SentryDiscardReason)reason;

- (void)addAttachmentProcessor:(id<BuzzSentryClientAttachmentProcessor>)attachmentProcessor;
- (void)removeAttachmentProcessor:(id<BuzzSentryClientAttachmentProcessor>)attachmentProcessor;

@end

NS_ASSUME_NONNULL_END
