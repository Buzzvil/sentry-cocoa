#import "BuzzSentryDataCategory.h"
#import "BuzzSentryDefines.h"
#import "BuzzSentryDiscardReason.h"
#import "BuzzSentryTransport.h"

@class BuzzSentryEnvelope, BuzzSentryEnvelopeItem, BuzzSentryEvent, BuzzSentrySession, BuzzSentryUserFeedback,
    BuzzSentryAttachment, BuzzSentryTraceContext, BuzzSentryOptions;

NS_ASSUME_NONNULL_BEGIN

/**
 * This class converts data objects to a BuzzSentryEnvelope and passes the BuzzSentryEnvelope to the
 * BuzzSentryTransport. It is a layer between the BuzzSentryClient and the transport to keep the
 * BuzzSentryClient small and make testing easier for the BuzzSentryClient.
 */
@interface BuzzSentryTransportAdapter : NSObject
SENTRY_NO_INIT

- (instancetype)initWithTransport:(id<BuzzSentryTransport>)transport options:(BuzzSentryOptions *)options;

- (void)sendEvent:(BuzzSentryEvent *)event
      attachments:(NSArray<BuzzSentryAttachment *> *)attachments
    NS_SWIFT_NAME(send(event:attachments:));

- (void)sendEvent:(BuzzSentryEvent *)event
          session:(BuzzSentrySession *)session
      attachments:(NSArray<BuzzSentryAttachment *> *)attachments;

- (void)sendEvent:(BuzzSentryEvent *)event
     traceContext:(nullable BuzzSentryTraceContext *)traceContext
      attachments:(NSArray<BuzzSentryAttachment *> *)attachments
    NS_SWIFT_NAME(send(event:traceContext:attachments:));

- (void)sendEvent:(BuzzSentryEvent *)event
               traceContext:(nullable BuzzSentryTraceContext *)traceContext
                attachments:(NSArray<BuzzSentryAttachment *> *)attachments
    additionalEnvelopeItems:(NSArray<BuzzSentryEnvelopeItem *> *)additionalEnvelopeItems
    NS_SWIFT_NAME(send(event:traceContext:attachments:additionalEnvelopeItems:));

- (void)sendEvent:(BuzzSentryEvent *)event
      withSession:(BuzzSentrySession *)session
     traceContext:(nullable BuzzSentryTraceContext *)traceContext
      attachments:(NSArray<BuzzSentryAttachment *> *)attachments;

- (void)sendUserFeedback:(BuzzSentryUserFeedback *)userFeedback NS_SWIFT_NAME(send(userFeedback:));

- (void)sendEnvelope:(BuzzSentryEnvelope *)envelope NS_SWIFT_NAME(send(envelope:));

- (void)recordLostEvent:(BuzzSentryDataCategory)category reason:(BuzzSentryDiscardReason)reason;

- (void)flush:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END
