#import "SentryDataCategory.h"
#import "SentryDefines.h"
#import "SentryDiscardReason.h"
#import "SentryTransport.h"

@class SentryEnvelope, SentryEnvelopeItem, SentryEvent, SentrySession, BuzzSentryUserFeedback,
    BuzzSentryAttachment, BuzzSentryTraceContext, BuzzSentryOptions;

NS_ASSUME_NONNULL_BEGIN

/**
 * This class converts data objects to a SentryEnvelope and passes the SentryEnvelope to the
 * SentryTransport. It is a layer between the BuzzSentryClient and the transport to keep the
 * BuzzSentryClient small and make testing easier for the BuzzSentryClient.
 */
@interface SentryTransportAdapter : NSObject
SENTRY_NO_INIT

- (instancetype)initWithTransport:(id<SentryTransport>)transport options:(BuzzSentryOptions *)options;

- (void)sendEvent:(SentryEvent *)event
      attachments:(NSArray<BuzzSentryAttachment *> *)attachments
    NS_SWIFT_NAME(send(event:attachments:));

- (void)sendEvent:(SentryEvent *)event
          session:(SentrySession *)session
      attachments:(NSArray<BuzzSentryAttachment *> *)attachments;

- (void)sendEvent:(SentryEvent *)event
     traceContext:(nullable BuzzSentryTraceContext *)traceContext
      attachments:(NSArray<BuzzSentryAttachment *> *)attachments
    NS_SWIFT_NAME(send(event:traceContext:attachments:));

- (void)sendEvent:(SentryEvent *)event
               traceContext:(nullable BuzzSentryTraceContext *)traceContext
                attachments:(NSArray<BuzzSentryAttachment *> *)attachments
    additionalEnvelopeItems:(NSArray<SentryEnvelopeItem *> *)additionalEnvelopeItems
    NS_SWIFT_NAME(send(event:traceContext:attachments:additionalEnvelopeItems:));

- (void)sendEvent:(SentryEvent *)event
      withSession:(SentrySession *)session
     traceContext:(nullable BuzzSentryTraceContext *)traceContext
      attachments:(NSArray<BuzzSentryAttachment *> *)attachments;

- (void)sendUserFeedback:(BuzzSentryUserFeedback *)userFeedback NS_SWIFT_NAME(send(userFeedback:));

- (void)sendEnvelope:(SentryEnvelope *)envelope NS_SWIFT_NAME(send(envelope:));

- (void)recordLostEvent:(SentryDataCategory)category reason:(SentryDiscardReason)reason;

- (void)flush:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END
