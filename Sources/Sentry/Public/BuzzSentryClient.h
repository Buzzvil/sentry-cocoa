#import "SentryDefines.h"

@class BuzzSentryOptions, BuzzSentrySession, BuzzSentryEvent, BuzzSentryEnvelope, SentryScope, SentryFileManager,
    BuzzSentryId, BuzzSentryUserFeedback, BuzzSentryTransaction;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Client)
@interface BuzzSentryClient : NSObject
SENTRY_NO_INIT

@property (nonatomic, strong) BuzzSentryOptions *options;

/**
 * Initializes a BuzzSentryClient. Pass in an dictionary of options.
 *
 * @param options Options dictionary
 * @return BuzzSentryClient
 */
- (_Nullable instancetype)initWithOptions:(BuzzSentryOptions *)options;

/**
 * Captures a manually created event and sends it to Sentry.
 *
 * @param event The event to send to Sentry.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
- (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event NS_SWIFT_NAME(capture(event:));

/**
 * Captures a manually created event and sends it to Sentry.
 *
 * @param event The event to send to Sentry.
 * @param scope The scope containing event metadata.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
- (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event
                 withScope:(SentryScope *)scope NS_SWIFT_NAME(capture(event:scope:));

/**
 * Captures an error event and sends it to Sentry.
 *
 * @param error The error to send to Sentry.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
- (BuzzSentryId *)captureError:(NSError *)error NS_SWIFT_NAME(capture(error:));

/**
 * Captures an error event and sends it to Sentry.
 *
 * @param error The error to send to Sentry.
 * @param scope The scope containing event metadata.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
- (BuzzSentryId *)captureError:(NSError *)error
                 withScope:(SentryScope *)scope NS_SWIFT_NAME(capture(error:scope:));

/**
 * Captures an exception event and sends it to Sentry.
 *
 * @param exception The exception to send to Sentry.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
- (BuzzSentryId *)captureException:(NSException *)exception NS_SWIFT_NAME(capture(exception:));

/**
 * Captures an exception event and sends it to Sentry.
 *
 * @param exception The exception to send to Sentry.
 * @param scope The scope containing event metadata.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
- (BuzzSentryId *)captureException:(NSException *)exception
                     withScope:(SentryScope *)scope NS_SWIFT_NAME(capture(exception:scope:));

/**
 * Captures a message event and sends it to Sentry.
 *
 * @param message The message to send to Sentry.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
- (BuzzSentryId *)captureMessage:(NSString *)message NS_SWIFT_NAME(capture(message:));

/**
 * Captures a message event and sends it to Sentry.
 *
 * @param message The message to send to Sentry.
 * @param scope The scope containing event metadata.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
- (BuzzSentryId *)captureMessage:(NSString *)message
                   withScope:(SentryScope *)scope NS_SWIFT_NAME(capture(message:scope:));

/**
 * Captures a manually created user feedback and sends it to Sentry.
 *
 * @param userFeedback The user feedback to send to Sentry.
 */
- (void)captureUserFeedback:(BuzzSentryUserFeedback *)userFeedback
    NS_SWIFT_NAME(capture(userFeedback:));

- (void)captureSession:(BuzzSentrySession *)session NS_SWIFT_NAME(capture(session:));

- (void)captureEnvelope:(BuzzSentryEnvelope *)envelope NS_SWIFT_NAME(capture(envelope:));

/**
 * Waits synchronously for the SDK to flush out all queued and cached items for up to the specified
 * timeout in seconds. If there is no internet connection, the function returns immediately. The SDK
 * doesn't dispose the client or the hub.
 *
 * @param timeout The time to wait for the SDK to complete the flush.
 */
- (void)flush:(NSTimeInterval)timeout NS_SWIFT_NAME(flush(timeout:));

@end

NS_ASSUME_NONNULL_END
