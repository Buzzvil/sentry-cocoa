#import "BuzzSentryDefines.h"
#import "BuzzSentryIntegrationProtocol.h"
#import "BuzzSentrySpanProtocol.h"

@class BuzzSentryEvent, BuzzSentryClient, BuzzSentryScope, BuzzSentrySession, BuzzSentryUser, BuzzSentryBreadcrumb,
    BuzzSentryId, BuzzSentryUserFeedback, BuzzSentryEnvelope, BuzzSentryTransactionContext;

NS_ASSUME_NONNULL_BEGIN
@interface BuzzSentryHub : NSObject
SENTRY_NO_INIT

- (instancetype)initWithClient:(BuzzSentryClient *_Nullable)client
                      andScope:(BuzzSentryScope *_Nullable)scope;

/**
 * Since there's no scope stack, single hub instance,  we keep the session here.
 */
@property (nonatomic, readonly, strong) BuzzSentrySession *_Nullable session;

/**
 * Starts a new BuzzSentrySession. If there's a running BuzzSentrySession, it ends it before starting the
 * new one. You can use this method in combination with endSession to manually track BuzzSentrySessions.
 * The SDK uses BuzzSentrySession to inform Sentry about release and project associated project health.
 */
- (void)startSession;

/**
 * Ends the current BuzzSentrySession. You can use this method in combination with startSession to
 * manually track BuzzSentrySessions. The SDK uses BuzzSentrySession to inform Sentry about release and
 * project associated project health.
 */
- (void)endSession;

/**
 * Ends the current session with the given timestamp.
 *
 * @param timestamp The timestamp to end the session with.
 */
- (void)endSessionWithTimestamp:(NSDate *)timestamp;

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
                 withScope:(BuzzSentryScope *)scope NS_SWIFT_NAME(capture(event:scope:));

/**
 * Creates a transaction, binds it to the hub and returns the instance.
 *
 * @param name The transaction name.
 * @param operation Short code identifying the type of operation the span is measuring.
 *
 * @return The created transaction.
 */
- (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
                                 operation:(NSString *)operation
    NS_SWIFT_NAME(startTransaction(name:operation:));

/**
 * Creates a transaction, binds it to the hub and returns the instance.
 *
 * @param name The transaction name.
 * @param operation Short code identifying the type of operation the span is measuring.
 * @param bindToScope Indicates whether the SDK should bind the new transaction to the scope.
 *
 * @return The created transaction.
 */
- (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
                                 operation:(NSString *)operation
                               bindToScope:(BOOL)bindToScope
    NS_SWIFT_NAME(startTransaction(name:operation:bindToScope:));

/**
 * Creates a transaction, binds it to the hub and returns the instance.
 *
 * @param transactionContext The transaction context.
 *
 * @return The created transaction.
 */
- (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
    NS_SWIFT_NAME(startTransaction(transactionContext:));

/**
 * Creates a transaction, binds it to the hub and returns the instance.
 *
 * @param transactionContext The transaction context.
 * @param bindToScope Indicates whether the SDK should bind the new transaction to the scope.
 *
 * @return The created transaction.
 */
- (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
    NS_SWIFT_NAME(startTransaction(transactionContext:bindToScope:));

/**
 * Creates a transaction, binds it to the hub and returns the instance.
 *
 * @param transactionContext The transaction context.
 * @param bindToScope Indicates whether the SDK should bind the new transaction to the scope.
 * @param customSamplingContext Additional information about the sampling context.
 *
 * @return The created transaction.
 */
- (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
    NS_SWIFT_NAME(startTransaction(transactionContext:bindToScope:customSamplingContext:));

/**
 * Creates a transaction, binds it to the hub and returns the instance.
 *
 * @param transactionContext The transaction context.
 * @param customSamplingContext Additional information about the sampling context.
 *
 * @return The created transaction.
 */
- (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
    NS_SWIFT_NAME(startTransaction(transactionContext:customSamplingContext:));

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
                 withScope:(BuzzSentryScope *)scope NS_SWIFT_NAME(capture(error:scope:));

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
                     withScope:(BuzzSentryScope *)scope NS_SWIFT_NAME(capture(exception:scope:));

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
                   withScope:(BuzzSentryScope *)scope NS_SWIFT_NAME(capture(message:scope:));

/**
 * Captures a manually created user feedback and sends it to Sentry.
 *
 * @param userFeedback The user feedback to send to Sentry.
 */
- (void)captureUserFeedback:(BuzzSentryUserFeedback *)userFeedback
    NS_SWIFT_NAME(capture(userFeedback:));

/**
 * Use this method to modify the Scope of the Hub. The SDK uses the Scope to attach
 * contextual data to events.
 *
 * @param callback The callback for configuring the Scope of the Hub.
 */
- (void)configureScope:(void (^)(BuzzSentryScope *scope))callback;

/**
 * Adds a breadcrumb to the Scope of the Hub.
 *
 * @param crumb The Breadcrumb to add to the Scope of the Hub.
 */
- (void)addBreadcrumb:(BuzzSentryBreadcrumb *)crumb;

/**
 * Returns a client if there is a bound client on the Hub.
 */
- (BuzzSentryClient *_Nullable)getClient;

/**
 * Returns either the current scope and if nil a new one.
 */
@property (nonatomic, readonly, strong) BuzzSentryScope *scope;

/**
 * Binds a different client to the hub.
 */
- (void)bindClient:(BuzzSentryClient *_Nullable)client;

/**
 * Checks if integration is activated.
 */
- (BOOL)hasIntegration:(NSString *)integrationName;

/**
 * Checks if a specific Integration (`integrationClass`) has been installed.
 *
 * @return BOOL If instance of `integrationClass` exists within `BuzzSentryHub.installedIntegrations`.
 */
- (BOOL)isIntegrationInstalled:(Class)integrationClass;

/**
 * Set user to the Scope of the Hub.
 *
 * @param user The user to set to the Scope.
 */
- (void)setUser:(BuzzSentryUser *_Nullable)user;

/**
 * The SDK reserves this method for hybrid SDKs, which use it to capture events.
 *
 * @discussion We increase the session error count if an envelope is passed in containing an
 * event with event.level error or higher. Ideally, we would check the mechanism and/or exception
 * list, like the Java and Python SDK do this, but this would require full deserialization of the
 * event.
 */
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
