#import "BuzzSentryTransportAdapter.h"
#import "BuzzSentryEnvelope.h"
#import "SentryEvent.h"
#import "BuzzSentryOptions.h"
#import "BuzzSentryUserFeedback.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryTransportAdapter ()

@property (nonatomic, strong) id<BuzzSentryTransport> transport;
@property (nonatomic, strong) BuzzSentryOptions *options;

@end

@implementation BuzzSentryTransportAdapter

- (instancetype)initWithTransport:(id<BuzzSentryTransport>)transport options:(BuzzSentryOptions *)options
{
    if (self = [super init]) {
        self.transport = transport;
        self.options = options;
    }

    return self;
}

- (void)sendEvent:(SentryEvent *)event attachments:(NSArray<BuzzSentryAttachment *> *)attachments
{
    [self sendEvent:event traceContext:nil attachments:attachments];
}

- (void)sendEvent:(SentryEvent *)event
          session:(SentrySession *)session
      attachments:(NSArray<BuzzSentryAttachment *> *)attachments
{
    [self sendEvent:event withSession:session traceContext:nil attachments:attachments];
}

- (void)sendEvent:(SentryEvent *)event
     traceContext:(nullable BuzzSentryTraceContext *)traceContext
      attachments:(NSArray<BuzzSentryAttachment *> *)attachments
{
    [self sendEvent:event
                   traceContext:traceContext
                    attachments:attachments
        additionalEnvelopeItems:@[]];
}

- (void)sendEvent:(SentryEvent *)event
               traceContext:(nullable BuzzSentryTraceContext *)traceContext
                attachments:(NSArray<BuzzSentryAttachment *> *)attachments
    additionalEnvelopeItems:(NSArray<BuzzSentryEnvelopeItem *> *)additionalEnvelopeItems
{
    NSMutableArray<BuzzSentryEnvelopeItem *> *items = [self buildEnvelopeItems:event
                                                               attachments:attachments];
    [items addObjectsFromArray:additionalEnvelopeItems];

    BuzzSentryEnvelopeHeader *envelopeHeader = [[BuzzSentryEnvelopeHeader alloc] initWithId:event.eventId
                                                                       traceContext:traceContext];
    BuzzSentryEnvelope *envelope = [[BuzzSentryEnvelope alloc] initWithHeader:envelopeHeader items:items];

    [self sendEnvelope:envelope];
}

- (void)sendEvent:(SentryEvent *)event
      withSession:(SentrySession *)session
     traceContext:(nullable BuzzSentryTraceContext *)traceContext
      attachments:(NSArray<BuzzSentryAttachment *> *)attachments
{
    NSMutableArray<BuzzSentryEnvelopeItem *> *items = [self buildEnvelopeItems:event
                                                               attachments:attachments];
    [items addObject:[[BuzzSentryEnvelopeItem alloc] initWithSession:session]];

    BuzzSentryEnvelopeHeader *envelopeHeader = [[BuzzSentryEnvelopeHeader alloc] initWithId:event.eventId
                                                                       traceContext:traceContext];

    BuzzSentryEnvelope *envelope = [[BuzzSentryEnvelope alloc] initWithHeader:envelopeHeader items:items];

    [self sendEnvelope:envelope];
}

- (void)sendUserFeedback:(BuzzSentryUserFeedback *)userFeedback
{
    BuzzSentryEnvelopeItem *item = [[BuzzSentryEnvelopeItem alloc] initWithUserFeedback:userFeedback];
    BuzzSentryEnvelopeHeader *envelopeHeader =
        [[BuzzSentryEnvelopeHeader alloc] initWithId:userFeedback.eventId traceContext:nil];
    BuzzSentryEnvelope *envelope = [[BuzzSentryEnvelope alloc] initWithHeader:envelopeHeader
                                                           singleItem:item];
    [self sendEnvelope:envelope];
}

- (void)sendEnvelope:(BuzzSentryEnvelope *)envelope
{
    [self.transport sendEnvelope:envelope];
}

- (void)recordLostEvent:(BuzzSentryDataCategory)category reason:(BuzzSentryDiscardReason)reason
{
    [self.transport recordLostEvent:category reason:reason];
}

- (void)flush:(NSTimeInterval)timeout
{
    [self.transport flush:timeout];
}

- (NSMutableArray<BuzzSentryEnvelopeItem *> *)buildEnvelopeItems:(SentryEvent *)event
                                                 attachments:
                                                     (NSArray<BuzzSentryAttachment *> *)attachments
{
    NSMutableArray<BuzzSentryEnvelopeItem *> *items = [NSMutableArray new];
    [items addObject:[[BuzzSentryEnvelopeItem alloc] initWithEvent:event]];

    for (BuzzSentryAttachment *attachment in attachments) {
        BuzzSentryEnvelopeItem *item =
            [[BuzzSentryEnvelopeItem alloc] initWithAttachment:attachment
                                         maxAttachmentSize:self.options.maxAttachmentSize];
        // The item is nil, when creating the envelopeItem failed.
        if (nil != item) {
            [items addObject:item];
        }
    }

    return items;
}

@end

NS_ASSUME_NONNULL_END
