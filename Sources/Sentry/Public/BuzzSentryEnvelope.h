#import <Foundation/Foundation.h>

#import <BuzzSentry/BuzzSentryDefines.h>

@class BuzzSentryEvent, BuzzSentrySession, BuzzSentrySDKInfo, BuzzSentryId, BuzzSentryUserFeedback, BuzzSentryAttachment,
    BuzzSentryTransaction, BuzzSentryTraceContext, BuzzSentryClientReport;

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryEnvelopeHeader : NSObject
SENTRY_NO_INIT

/**
 * Initializes an BuzzSentryEnvelopeHeader object with the specified eventId.
 *
 * Sets the sdkInfo from BuzzSentryMeta.
 *
 * @param eventId The identifier of the event. Can be nil if no event in the envelope or attachment
 * related to event.
 */
- (instancetype)initWithId:(BuzzSentryId *_Nullable)eventId;

/**
 * Initializes an BuzzSentryEnvelopeHeader object with the specified eventId and traceContext.
 *
 * @param eventId The identifier of the event. Can be nil if no event in the envelope or attachment
 * related to event.
 * @param traceContext Current trace state.
 */
- (instancetype)initWithId:(nullable BuzzSentryId *)eventId
              traceContext:(nullable BuzzSentryTraceContext *)traceContext;

/**
 * Initializes an BuzzSentryEnvelopeHeader object with the specified eventId, skdInfo and traceContext.
 *
 * It is recommended to use initWithId:traceContext: because it sets the sdkInfo for you.
 *
 * @param eventId The identifier of the event. Can be nil if no event in the envelope or attachment
 * related to event.
 * @param sdkInfo sdkInfo Describes the Sentry SDK. Can be nil for backwards compatibility. New
 * instances should always provide a version.
 * @param traceContext Current trace state.
 */
- (instancetype)initWithId:(nullable BuzzSentryId *)eventId
                   sdkInfo:(nullable BuzzSentrySDKInfo *)sdkInfo
              traceContext:(nullable BuzzSentryTraceContext *)traceContext NS_DESIGNATED_INITIALIZER;

/**
 * The event identifier, if available.
 * An event id exist if the envelope contains an event of items within it are
 * related. i.e Attachments
 */
@property (nullable, nonatomic, readonly, copy) BuzzSentryId *eventId;

@property (nullable, nonatomic, readonly, copy) BuzzSentrySDKInfo *sdkInfo;

@property (nullable, nonatomic, readonly, copy) BuzzSentryTraceContext *traceContext;

@end

@interface BuzzSentryEnvelopeItemHeader : NSObject
SENTRY_NO_INIT

- (instancetype)initWithType:(NSString *)type length:(NSUInteger)length NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithType:(NSString *)type
                      length:(NSUInteger)length
                   filenname:(NSString *)filename
                 contentType:(NSString *)contentType;

/**
 * The type of the envelope item.
 */
@property (nonatomic, readonly, copy) NSString *type;
@property (nonatomic, readonly) NSUInteger length;
@property (nonatomic, readonly, copy) NSString *_Nullable filename;
@property (nonatomic, readonly, copy) NSString *_Nullable contentType;

@end

@interface BuzzSentryEnvelopeItem : NSObject
SENTRY_NO_INIT

- (instancetype)initWithEvent:(BuzzSentryEvent *)event;
- (instancetype)initWithSession:(BuzzSentrySession *)session;
- (instancetype)initWithUserFeedback:(BuzzSentryUserFeedback *)userFeedback;
- (_Nullable instancetype)initWithAttachment:(BuzzSentryAttachment *)attachment
                           maxAttachmentSize:(NSUInteger)maxAttachmentSize;
- (instancetype)initWithHeader:(BuzzSentryEnvelopeItemHeader *)header
                          data:(NSData *)data NS_DESIGNATED_INITIALIZER;

/**
 * The envelope item header.
 */
@property (nonatomic, readonly, strong) BuzzSentryEnvelopeItemHeader *header;

/**
 * The envelope payload.
 */
@property (nonatomic, readonly, strong) NSData *data;

@end

@interface BuzzSentryEnvelope : NSObject
SENTRY_NO_INIT

// If no event, or no data related to event, id will be null
- (instancetype)initWithId:(BuzzSentryId *_Nullable)id singleItem:(BuzzSentryEnvelopeItem *)item;

- (instancetype)initWithHeader:(BuzzSentryEnvelopeHeader *)header singleItem:(BuzzSentryEnvelopeItem *)item;

// If no event, or no data related to event, id will be null
- (instancetype)initWithId:(BuzzSentryId *_Nullable)id items:(NSArray<BuzzSentryEnvelopeItem *> *)items;

/**
 * Initializes a BuzzSentryEnvelope with a single session.
 * @param session to init the envelope with.
 * @return an initialized BuzzSentryEnvelope
 */
- (instancetype)initWithSession:(BuzzSentrySession *)session;

/**
 * Initializes a BuzzSentryEnvelope with a list of sessions.
 * Can be used when an operations that starts a session closes an ongoing
 * session
 * @param sessions to init the envelope with.
 * @return an initialized BuzzSentryEnvelope
 */
- (instancetype)initWithSessions:(NSArray<BuzzSentrySession *> *)sessions;

- (instancetype)initWithHeader:(BuzzSentryEnvelopeHeader *)header
                         items:(NSArray<BuzzSentryEnvelopeItem *> *)items NS_DESIGNATED_INITIALIZER;

// Convenience init for a single event
- (instancetype)initWithEvent:(BuzzSentryEvent *)event;

- (instancetype)initWithUserFeedback:(BuzzSentryUserFeedback *)userFeedback;

/**
 * The envelope header.
 */
@property (nonatomic, readonly, strong) BuzzSentryEnvelopeHeader *header;

/**
 * The envelope items.
 */
@property (nonatomic, readonly, strong) NSArray<BuzzSentryEnvelopeItem *> *items;

@end

NS_ASSUME_NONNULL_END
