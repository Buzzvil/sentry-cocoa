#import <BuzzSentry/BuzzSentryDefines.h>

@protocol BuzzSentrySpan;

@class BuzzSentryOptions, BuzzSentryEvent, BuzzSentryBreadcrumb, BuzzSentryScope, BuzzSentryUser, BuzzSentryId,
    BuzzSentryUserFeedback, BuzzSentryTransactionContext;

NS_ASSUME_NONNULL_BEGIN

/**
 * The main entry point for the BuzzSentrySDK.
 *
 * We recommend using `[Sentry startWithConfigureOptions]` to initialize Sentry.
 */
@interface BuzzSentrySDK : NSObject
SENTRY_NO_INIT

/**
 * The current active transaction or span bound to the scope.
 */
@property (nullable, class, nonatomic, readonly) id<BuzzSentrySpan> span;

/**
 * Indicates whether the BuzzSentrySDK is enabled.
 */
@property (class, nonatomic, readonly) BOOL isEnabled;

/**
 * Inits and configures Sentry (BuzzSentryHub, BuzzSentryClient) and sets up all integrations.
 */
+ (void)startWithOptions:(NSDictionary<NSString *, id> *)optionsDict NS_SWIFT_NAME(start(options:));

/**
 * Inits and configures Sentry (BuzzSentryHub, BuzzSentryClient) and sets up all integrations.
 */
+ (void)startWithOptionsObject:(BuzzSentryOptions *)options NS_SWIFT_NAME(start(options:));

/**
 * Inits and configures Sentry (BuzzSentryHub, BuzzSentryClient) and sets up all integrations. Make sure to
 * set a valid DSN.
 */
+ (void)startWithConfigureOptions:(void (^)(BuzzSentryOptions *options))configureOptions
    NS_SWIFT_NAME(start(configureOptions:));

/**
 * Captures a manually created event and sends it to Sentry.
 *
 * @param event The event to send to Sentry.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
+ (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event NS_SWIFT_NAME(capture(event:));

/**
 * Captures a manually created event and sends it to Sentry. Only the data in this scope object will
 * be added to the event. The global scope will be ignored.
 *
 * @param event The event to send to Sentry.
 * @param scope The scope containing event metadata.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
+ (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event
                 withScope:(BuzzSentryScope *)scope NS_SWIFT_NAME(capture(event:scope:));

/**
 * Captures a manually created event and sends it to Sentry. Maintains the global scope but mutates
 * scope data for only this call.
 *
 * @param event The event to send to Sentry.
 * @param block The block mutating the scope only for this call.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
+ (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event
            withScopeBlock:(void (^)(BuzzSentryScope *scope))block NS_SWIFT_NAME(capture(event:block:));

/**
 * Creates a transaction, binds it to the hub and returns the instance.
 *
 * @param name The transaction name.
 * @param operation Short code identifying the type of operation the span is measuring.
 *
 * @return The created transaction.
 */
+ (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
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
+ (id<BuzzSentrySpan>)startTransactionWithName:(NSString *)name
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
+ (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
    NS_SWIFT_NAME(startTransaction(transactionContext:));

/**
 * Creates a transaction, binds it to the hub and returns the instance.
 *
 * @param transactionContext The transaction context.
 * @param bindToScope Indicates whether the SDK should bind the new transaction to the scope.
 *
 * @return The created transaction.
 */
+ (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
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
+ (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
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
+ (id<BuzzSentrySpan>)startTransactionWithContext:(BuzzSentryTransactionContext *)transactionContext
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
    NS_SWIFT_NAME(startTransaction(transactionContext:customSamplingContext:));

/**
 * Captures an error event and sends it to Sentry.
 *
 * @param error The error to send to Sentry.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
+ (BuzzSentryId *)captureError:(NSError *)error NS_SWIFT_NAME(capture(error:));

/**
 * Captures an error event and sends it to Sentry. Only the data in this scope object will be added
 * to the event. The global scope will be ignored.
 *
 * @param error The error to send to Sentry.
 * @param scope The scope containing event metadata.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
+ (BuzzSentryId *)captureError:(NSError *)error
                 withScope:(BuzzSentryScope *)scope NS_SWIFT_NAME(capture(error:scope:));

/**
 * Captures an error event and sends it to Sentry. Maintains the global scope but mutates scope data
 * for only this call.
 *
 * @param error The error to send to Sentry.
 * @param block The block mutating the scope only for this call.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
+ (BuzzSentryId *)captureError:(NSError *)error
            withScopeBlock:(void (^)(BuzzSentryScope *scope))block NS_SWIFT_NAME(capture(error:block:));

/**
 * Captures an exception event and sends it to Sentry.
 *
 * @param exception The exception to send to Sentry.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
+ (BuzzSentryId *)captureException:(NSException *)exception NS_SWIFT_NAME(capture(exception:));

/**
 * Captures an exception event and sends it to Sentry. Only the data in this scope object will be
 * added to the event. The global scope will be ignored.
 *
 * @param exception The exception to send to Sentry.
 * @param scope The scope containing event metadata.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
+ (BuzzSentryId *)captureException:(NSException *)exception
                     withScope:(BuzzSentryScope *)scope NS_SWIFT_NAME(capture(exception:scope:));

/**
 * Captures an exception event and sends it to Sentry. Maintains the global scope but mutates scope
 * data for only this call.
 *
 * @param exception The exception to send to Sentry.
 * @param block The block mutating the scope only for this call.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
+ (BuzzSentryId *)captureException:(NSException *)exception
                withScopeBlock:(void (^)(BuzzSentryScope *scope))block
    NS_SWIFT_NAME(capture(exception:block:));

/**
 * Captures a message event and sends it to Sentry.
 *
 * @param message The message to send to Sentry.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
+ (BuzzSentryId *)captureMessage:(NSString *)message NS_SWIFT_NAME(capture(message:));

/**
 * Captures a message event and sends it to Sentry. Only the data in this scope object will be added
 * to the event. The global scope will be ignored.
 *
 * @param message The message to send to Sentry.
 * @param scope The scope containing event metadata.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
+ (BuzzSentryId *)captureMessage:(NSString *)message
                   withScope:(BuzzSentryScope *)scope NS_SWIFT_NAME(capture(message:scope:));

/**
 * Captures a message event and sends it to Sentry. Maintains the global scope but mutates scope
 * data for only this call.
 *
 * @param message The message to send to Sentry.
 * @param block The block mutating the scope only for this call.
 *
 * @return The BuzzSentryId of the event or BuzzSentryId.empty if the event is not sent.
 */
+ (BuzzSentryId *)captureMessage:(NSString *)message
              withScopeBlock:(void (^)(BuzzSentryScope *scope))block
    NS_SWIFT_NAME(capture(message:block:));

/**
 * Captures a manually created user feedback and sends it to Sentry.
 *
 * @param userFeedback The user feedback to send to Sentry.
 */
+ (void)captureUserFeedback:(BuzzSentryUserFeedback *)userFeedback
    NS_SWIFT_NAME(capture(userFeedback:));

/**
 * Adds a Breadcrumb to the current Scope of the current Hub. If the total number of breadcrumbs
 * exceeds the `BuzzSentryOptions.maxBreadcrumbs`, the SDK removes the oldest breadcrumb.
 *
 * @param crumb The Breadcrumb to add to the current Scope of the current Hub.
 */
+ (void)addBreadcrumb:(BuzzSentryBreadcrumb *)crumb NS_SWIFT_NAME(addBreadcrumb(crumb:));

/**
 * Use this method to modify the current Scope of the current Hub. The SDK uses the Scope to attach
 * contextual data to events.
 *
 * @param callback The callback for configuring the current Scope of the current Hub.
 */
+ (void)configureScope:(void (^)(BuzzSentryScope *scope))callback;

/**
 * Checks if the last program execution terminated with a crash.
 */
@property (nonatomic, class, readonly) BOOL crashedLastRun;

/**
 * Set user to the current Scope of the current Hub.
 *
 * @param user The user to set to the current Scope.
 */
+ (void)setUser:(BuzzSentryUser *_Nullable)user;

/**
 * Starts a new BuzzSentrySession. If there's a running BuzzSentrySession, it ends it before starting the
 * new one. You can use this method in combination with endSession to manually track BuzzSentrySessions.
 * The SDK uses BuzzSentrySession to inform Sentry about release and project associated project health.
 */
+ (void)startSession;

/**
 * Ends the current BuzzSentrySession. You can use this method in combination with startSession to
 * manually track BuzzSentrySessions. The SDK uses BuzzSentrySession to inform Sentry about release and
 * project associated project health.
 */
+ (void)endSession;

/**
 * This forces a crash, useful to test the SentryCrash integration
 */
+ (void)crash;

/**
 * Waits synchronously for the SDK to flush out all queued and cached items for up to the specified
 * timeout in seconds. If there is no internet connection, the function returns immediately. The SDK
 * doesn't dispose the client or the hub.
 *
 * @param timeout The time to wait for the SDK to complete the flush.
 */
+ (void)flush:(NSTimeInterval)timeout NS_SWIFT_NAME(flush(timeout:));

/**
 * Closes the SDK and uninstalls all the integrations.
 */
+ (void)close;

@end

NS_ASSUME_NONNULL_END
