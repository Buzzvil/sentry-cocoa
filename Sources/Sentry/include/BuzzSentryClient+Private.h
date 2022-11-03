#import "BuzzSentryClient.h"
#import "BuzzSentryDataCategory.h"
#import "BuzzSentryDiscardReason.h"

@class BuzzSentryEnvelopeItem, BuzzSentryId, BuzzSentryAttachment, BuzzSentryThreadInspector;

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
@property (nonatomic, strong) BuzzSentryThreadInspector *threadInspector;

- (BuzzSentryFileManager *)fileManager;

- (BuzzSentryId *)captureError:(NSError *)error
               withSession:(BuzzSentrySession *)session
                 withScope:(BuzzSentryScope *)scope;

- (BuzzSentryId *)captureException:(NSException *)exception
                   withSession:(BuzzSentrySession *)session
                     withScope:(BuzzSentryScope *)scope;

- (BuzzSentryId *)captureCrashEvent:(BuzzSentryEvent *)event withScope:(BuzzSentryScope *)scope;

- (BuzzSentryId *)captureCrashEvent:(BuzzSentryEvent *)event
                    withSession:(BuzzSentrySession *)session
                      withScope:(BuzzSentryScope *)scope;

- (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event
                  withScope:(BuzzSentryScope *)scope
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
