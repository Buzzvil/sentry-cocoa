#import "BuzzSentryClient.h"
#import "NSDictionary+SentrySanitize.h"
#import "NSLocale+Sentry.h"
#import "BuzzSentryAttachment.h"
#import "BuzzSentryClient+Private.h"
#import "SentryCrashDefaultMachineContextWrapper.h"
#import "BuzzSentryCrashIntegration.h"
#import "SentryCrashStackEntryMapper.h"
#import "SentryCrashWrapper.h"
#import "SentryDebugImageProvider.h"
#import "SentryDefaultCurrentDateProvider.h"
#import "SentryDependencyContainer.h"
#import "BuzzSentryDsn.h"
#import "BuzzSentryEnvelope.h"
#import "BuzzSentryEnvelopeItemType.h"
#import "BuzzSentryEvent.h"
#import "SentryException.h"
#import "SentryFileManager.h"
#import "SentryGlobalEventProcessor.h"
#import "BuzzSentryHub+Private.h"
#import "BuzzSentryHub.h"
#import "BuzzSentryId.h"
#import "SentryInAppLogic.h"
#import "SentryInstallation.h"
#import "SentryLog.h"
#import "BuzzSentryMechanism.h"
#import "BuzzSentryMechanismMeta.h"
#import "BuzzSentryMessage.h"
#import "BuzzSentryMeta.h"
#import "BuzzSentryNSError.h"
#import "BuzzSentryOptions+Private.h"
#import "BuzzSentryOutOfMemoryTracker.h"
#import "SentryPermissionsObserver.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentryScope+Private.h"
#import "BuzzSentrySdkInfo.h"
#import "BuzzSentryStacktraceBuilder.h"
#import "SentryThreadInspector.h"
#import "BuzzSentryTraceContext.h"
#import "BuzzSentryTracer.h"
#import "BuzzSentryTransaction.h"
#import "BuzzSentryTransport.h"
#import "BuzzSentryTransportAdapter.h"
#import "BuzzSentryTransportFactory.h"
#import "SentryUIDeviceWrapper.h"
#import "BuzzSentryUser.h"
#import "BuzzSentryUserFeedback.h"

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryClient ()

@property (nonatomic, strong) BuzzSentryTransportAdapter *transportAdapter;
@property (nonatomic, strong) SentryFileManager *fileManager;
@property (nonatomic, strong) SentryDebugImageProvider *debugImageProvider;
@property (nonatomic, strong) SentryThreadInspector *threadInspector;
@property (nonatomic, strong) id<BuzzSentryRandom> random;
@property (nonatomic, strong)
    NSMutableArray<id<BuzzSentryClientAttachmentProcessor>> *attachmentProcessors;
@property (nonatomic, strong) SentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) SentryPermissionsObserver *permissionsObserver;
@property (nonatomic, strong) SentryUIDeviceWrapper *deviceWrapper;
@property (nonatomic, strong) NSLocale *locale;
@property (nonatomic, strong) NSTimeZone *timezone;

@end

NSString *const DropSessionLogMessage = @"Session has no release name. Won't send it.";
NSString *const kSentryDefaultEnvironment = @"production";

@implementation BuzzSentryClient

- (_Nullable instancetype)initWithOptions:(BuzzSentryOptions *)options
{
    return [self initWithOptions:options
             permissionsObserver:[[SentryPermissionsObserver alloc] init]];
}

/** Internal constructors for testing */
- (_Nullable instancetype)initWithOptions:(BuzzSentryOptions *)options
                      permissionsObserver:(SentryPermissionsObserver *)permissionsObserver
{
    NSError *error = nil;
    SentryFileManager *fileManager =
        [[SentryFileManager alloc] initWithOptions:options
                            andCurrentDateProvider:[SentryDefaultCurrentDateProvider sharedInstance]
                                             error:&error];
    if (nil != error) {
        SENTRY_LOG_ERROR(@"%@", error.localizedDescription);
        return nil;
    }

    id<BuzzSentryTransport> transport = [BuzzSentryTransportFactory initTransport:options
                                                        sentryFileManager:fileManager];

    BuzzSentryTransportAdapter *transportAdapter =
        [[BuzzSentryTransportAdapter alloc] initWithTransport:transport options:options];

    SentryInAppLogic *inAppLogic =
        [[SentryInAppLogic alloc] initWithInAppIncludes:options.inAppIncludes
                                          inAppExcludes:options.inAppExcludes];
    SentryCrashStackEntryMapper *crashStackEntryMapper =
        [[SentryCrashStackEntryMapper alloc] initWithInAppLogic:inAppLogic];
    BuzzSentryStacktraceBuilder *stacktraceBuilder =
        [[BuzzSentryStacktraceBuilder alloc] initWithCrashStackEntryMapper:crashStackEntryMapper];
    id<SentryCrashMachineContextWrapper> machineContextWrapper =
        [[SentryCrashDefaultMachineContextWrapper alloc] init];
    SentryThreadInspector *threadInspector =
        [[SentryThreadInspector alloc] initWithStacktraceBuilder:stacktraceBuilder
                                        andMachineContextWrapper:machineContextWrapper];
    SentryUIDeviceWrapper *deviceWrapper = [[SentryUIDeviceWrapper alloc] init];

    return [self initWithOptions:options
                transportAdapter:transportAdapter
                     fileManager:fileManager
                 threadInspector:threadInspector
                          random:[SentryDependencyContainer sharedInstance].random
                    crashWrapper:[SentryCrashWrapper sharedInstance]
             permissionsObserver:permissionsObserver
                   deviceWrapper:deviceWrapper
                          locale:[NSLocale autoupdatingCurrentLocale]
                        timezone:[NSCalendar autoupdatingCurrentCalendar].timeZone];
}

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
               transportAdapter:(BuzzSentryTransportAdapter *)transportAdapter
                    fileManager:(SentryFileManager *)fileManager
                threadInspector:(SentryThreadInspector *)threadInspector
                         random:(id<BuzzSentryRandom>)random
                   crashWrapper:(SentryCrashWrapper *)crashWrapper
            permissionsObserver:(SentryPermissionsObserver *)permissionsObserver
                  deviceWrapper:(SentryUIDeviceWrapper *)deviceWrapper
                         locale:(NSLocale *)locale
                       timezone:(NSTimeZone *)timezone
{
    if (self = [super init]) {
        self.options = options;
        self.transportAdapter = transportAdapter;
        self.fileManager = fileManager;
        self.threadInspector = threadInspector;
        self.random = random;
        self.crashWrapper = crashWrapper;
        self.permissionsObserver = permissionsObserver;
        self.debugImageProvider = [SentryDependencyContainer sharedInstance].debugImageProvider;
        self.locale = locale;
        self.timezone = timezone;
        self.attachmentProcessors = [[NSMutableArray alloc] init];
        self.deviceWrapper = deviceWrapper;
    }
    return self;
}

- (SentryFileManager *)fileManager
{
    return _fileManager;
}

- (BuzzSentryId *)captureMessage:(NSString *)message
{
    return [self captureMessage:message withScope:[[BuzzSentryScope alloc] init]];
}

- (BuzzSentryId *)captureMessage:(NSString *)message withScope:(BuzzSentryScope *)scope
{
    BuzzSentryEvent *event = [[BuzzSentryEvent alloc] initWithLevel:kSentryLevelInfo];
    event.message = [[BuzzSentryMessage alloc] initWithFormatted:message];
    return [self sendEvent:event withScope:scope alwaysAttachStacktrace:NO];
}

- (BuzzSentryId *)captureException:(NSException *)exception
{
    return [self captureException:exception withScope:[[BuzzSentryScope alloc] init]];
}

- (BuzzSentryId *)captureException:(NSException *)exception withScope:(BuzzSentryScope *)scope
{
    BuzzSentryEvent *event = [self buildExceptionEvent:exception];
    return [self sendEvent:event withScope:scope alwaysAttachStacktrace:YES];
}

- (BuzzSentryId *)captureException:(NSException *)exception
                   withSession:(BuzzSentrySession *)session
                     withScope:(BuzzSentryScope *)scope
{
    BuzzSentryEvent *event = [self buildExceptionEvent:exception];
    event = [self prepareEvent:event withScope:scope alwaysAttachStacktrace:YES];
    return [self sendEvent:event withSession:session withScope:scope];
}

- (BuzzSentryEvent *)buildExceptionEvent:(NSException *)exception
{
    BuzzSentryEvent *event = [[BuzzSentryEvent alloc] initWithLevel:kSentryLevelError];
    SentryException *sentryException = [[SentryException alloc] initWithValue:exception.reason
                                                                         type:exception.name];

    event.exceptions = @[ sentryException ];
    [self setUserInfo:exception.userInfo withEvent:event];
    return event;
}

- (BuzzSentryId *)captureError:(NSError *)error
{
    return [self captureError:error withScope:[[BuzzSentryScope alloc] init]];
}

- (BuzzSentryId *)captureError:(NSError *)error withScope:(BuzzSentryScope *)scope
{
    BuzzSentryEvent *event = [self buildErrorEvent:error];
    return [self sendEvent:event withScope:scope alwaysAttachStacktrace:YES];
}

- (BuzzSentryId *)captureError:(NSError *)error
               withSession:(BuzzSentrySession *)session
                 withScope:(BuzzSentryScope *)scope
{
    BuzzSentryEvent *event = [self buildErrorEvent:error];
    event = [self prepareEvent:event withScope:scope alwaysAttachStacktrace:YES];
    return [self sendEvent:event withSession:session withScope:scope];
}

- (BuzzSentryEvent *)buildErrorEvent:(NSError *)error
{
    BuzzSentryEvent *event = [[BuzzSentryEvent alloc] initWithError:error];

    NSString *exceptionValue;

    // If the error has a debug description, use that.
    NSString *customExceptionValue = [[error userInfo] valueForKey:NSDebugDescriptionErrorKey];
    if (customExceptionValue != nil) {
        exceptionValue =
            [NSString stringWithFormat:@"%@ (Code: %ld)", customExceptionValue, (long)error.code];
    } else {
        exceptionValue = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
    }
    SentryException *exception = [[SentryException alloc] initWithValue:exceptionValue
                                                                   type:error.domain];

    // Sentry uses the error domain and code on the mechanism for gouping
    BuzzSentryMechanism *mechanism = [[BuzzSentryMechanism alloc] initWithType:@"NSError"];
    BuzzSentryMechanismMeta *mechanismMeta = [[BuzzSentryMechanismMeta alloc] init];
    mechanismMeta.error = [[BuzzSentryNSError alloc] initWithDomain:error.domain code:error.code];
    mechanism.meta = mechanismMeta;
    // The description of the error can be especially useful for error from swift that
    // use a simple enum.
    mechanism.desc = error.description;

    NSDictionary<NSString *, id> *userInfo = [error.userInfo sentry_sanitize];
    mechanism.data = userInfo;
    exception.mechanism = mechanism;
    event.exceptions = @[ exception ];

    // Once the UI displays the mechanism data we can the userInfo from the event.context.
    [self setUserInfo:userInfo withEvent:event];

    return event;
}

- (BuzzSentryId *)captureCrashEvent:(BuzzSentryEvent *)event withScope:(BuzzSentryScope *)scope
{
    return [self sendEvent:event withScope:scope alwaysAttachStacktrace:NO isCrashEvent:YES];
}

- (BuzzSentryId *)captureCrashEvent:(BuzzSentryEvent *)event
                    withSession:(BuzzSentrySession *)session
                      withScope:(BuzzSentryScope *)scope
{
    BuzzSentryEvent *preparedEvent = [self prepareEvent:event
                                          withScope:scope
                             alwaysAttachStacktrace:NO
                                       isCrashEvent:YES];
    return [self sendEvent:preparedEvent withSession:session withScope:scope];
}

- (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event
{
    return [self captureEvent:event withScope:[[BuzzSentryScope alloc] init]];
}

- (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event withScope:(BuzzSentryScope *)scope
{
    return [self sendEvent:event withScope:scope alwaysAttachStacktrace:NO];
}

- (BuzzSentryId *)captureEvent:(BuzzSentryEvent *)event
                  withScope:(BuzzSentryScope *)scope
    additionalEnvelopeItems:(NSArray<BuzzSentryEnvelopeItem *> *)additionalEnvelopeItems
{
    return [self sendEvent:event
                      withScope:scope
         alwaysAttachStacktrace:NO
                   isCrashEvent:NO
        additionalEnvelopeItems:additionalEnvelopeItems];
}

- (BuzzSentryId *)sendEvent:(BuzzSentryEvent *)event
                 withScope:(BuzzSentryScope *)scope
    alwaysAttachStacktrace:(BOOL)alwaysAttachStacktrace
{
    return [self sendEvent:event
                     withScope:scope
        alwaysAttachStacktrace:alwaysAttachStacktrace
                  isCrashEvent:NO];
}

- (nullable BuzzSentryTraceContext *)getTraceStateWithEvent:(BuzzSentryEvent *)event
                                              withScope:(BuzzSentryScope *)scope
{
    id<BuzzSentrySpan> span;
    if ([event isKindOfClass:[BuzzSentryTransaction class]]) {
        span = [(BuzzSentryTransaction *)event trace];
    } else {
        // Even envelopes without transactions can contain the trace state, allowing Sentry to
        // eventually sample attachments belonging to a transaction.
        span = scope.span;
    }

    BuzzSentryTracer *tracer = [BuzzSentryTracer getTracer:span];
    if (tracer == nil)
        return nil;

    return [[BuzzSentryTraceContext alloc] initWithTracer:tracer scope:scope options:_options];
}

- (BuzzSentryId *)sendEvent:(BuzzSentryEvent *)event
                 withScope:(BuzzSentryScope *)scope
    alwaysAttachStacktrace:(BOOL)alwaysAttachStacktrace
              isCrashEvent:(BOOL)isCrashEvent
{
    return [self sendEvent:event
                      withScope:scope
         alwaysAttachStacktrace:alwaysAttachStacktrace
                   isCrashEvent:isCrashEvent
        additionalEnvelopeItems:@[]];
}

- (BuzzSentryId *)sendEvent:(BuzzSentryEvent *)event
                  withScope:(BuzzSentryScope *)scope
     alwaysAttachStacktrace:(BOOL)alwaysAttachStacktrace
               isCrashEvent:(BOOL)isCrashEvent
    additionalEnvelopeItems:(NSArray<BuzzSentryEnvelopeItem *> *)additionalEnvelopeItems
{
    BuzzSentryEvent *preparedEvent = [self prepareEvent:event
                                          withScope:scope
                             alwaysAttachStacktrace:alwaysAttachStacktrace
                                       isCrashEvent:isCrashEvent];

    if (nil != preparedEvent) {
        BuzzSentryTraceContext *traceContext = [self getTraceStateWithEvent:event withScope:scope];

        NSArray *attachments = scope.attachments;
        if (self.attachmentProcessors.count) {
            for (id<BuzzSentryClientAttachmentProcessor> attachmentProcessor in self
                     .attachmentProcessors) {
                attachments = [attachmentProcessor processAttachments:attachments
                                                             forEvent:preparedEvent];
            }
        }

        [self.transportAdapter sendEvent:preparedEvent
                            traceContext:traceContext
                             attachments:attachments
                 additionalEnvelopeItems:additionalEnvelopeItems];

        return preparedEvent.eventId;
    }

    return BuzzSentryId.empty;
}

- (BuzzSentryId *)sendEvent:(BuzzSentryEvent *)event
            withSession:(BuzzSentrySession *)session
              withScope:(BuzzSentryScope *)scope
{
    if (nil != event) {
        NSArray *attachments = scope.attachments;
        if (self.attachmentProcessors.count) {
            for (id<BuzzSentryClientAttachmentProcessor> attachmentProcessor in self
                     .attachmentProcessors) {
                attachments = [attachmentProcessor processAttachments:attachments forEvent:event];
            }
        }

        if (nil == session.releaseName || [session.releaseName length] == 0) {
            BuzzSentryTraceContext *traceContext = [self getTraceStateWithEvent:event withScope:scope];

            SENTRY_LOG_DEBUG(DropSessionLogMessage);

            [self.transportAdapter sendEvent:event
                                traceContext:traceContext
                                 attachments:attachments];
            return event.eventId;
        }

        [self.transportAdapter sendEvent:event session:session attachments:attachments];

        return event.eventId;
    } else {
        [self captureSession:session];
        return BuzzSentryId.empty;
    }
}

- (void)captureSession:(BuzzSentrySession *)session
{
    if (nil == session.releaseName || [session.releaseName length] == 0) {
        SENTRY_LOG_DEBUG(DropSessionLogMessage);
        return;
    }

    BuzzSentryEnvelopeItem *item = [[BuzzSentryEnvelopeItem alloc] initWithSession:session];
    BuzzSentryEnvelopeHeader *envelopeHeader = [[BuzzSentryEnvelopeHeader alloc] initWithId:nil
                                                                       traceContext:nil];
    BuzzSentryEnvelope *envelope = [[BuzzSentryEnvelope alloc] initWithHeader:envelopeHeader
                                                           singleItem:item];
    [self captureEnvelope:envelope];
}

- (void)captureEnvelope:(BuzzSentryEnvelope *)envelope
{
    // TODO: What is about beforeSend

    if ([self isDisabled]) {
        [self logDisabledMessage];
        return;
    }

    [self.transportAdapter sendEnvelope:envelope];
}

- (void)captureUserFeedback:(BuzzSentryUserFeedback *)userFeedback
{
    if ([self isDisabled]) {
        [self logDisabledMessage];
        return;
    }

    if ([BuzzSentryId.empty isEqual:userFeedback.eventId]) {
        SENTRY_LOG_DEBUG(@"Capturing UserFeedback with an empty event id. Won't send it.");
        return;
    }

    [self.transportAdapter sendUserFeedback:userFeedback];
}

- (void)storeEnvelope:(BuzzSentryEnvelope *)envelope
{
    [self.fileManager storeEnvelope:envelope];
}

- (void)recordLostEvent:(BuzzSentryDataCategory)category reason:(BuzzSentryDiscardReason)reason
{
    [self.transportAdapter recordLostEvent:category reason:reason];
}

- (BuzzSentryEvent *_Nullable)prepareEvent:(BuzzSentryEvent *)event
                             withScope:(BuzzSentryScope *)scope
                alwaysAttachStacktrace:(BOOL)alwaysAttachStacktrace
{
    return [self prepareEvent:event
                     withScope:scope
        alwaysAttachStacktrace:alwaysAttachStacktrace
                  isCrashEvent:NO];
}

- (void)flush:(NSTimeInterval)timeout
{
    [self.transportAdapter flush:timeout];
}

- (BuzzSentryEvent *_Nullable)prepareEvent:(BuzzSentryEvent *)event
                             withScope:(BuzzSentryScope *)scope
                alwaysAttachStacktrace:(BOOL)alwaysAttachStacktrace
                          isCrashEvent:(BOOL)isCrashEvent
{
    NSParameterAssert(event);
    if (event == nil) {
        return nil;
    }

    if ([self isDisabled]) {
        [self logDisabledMessage];
        return nil;
    }

    BOOL eventIsNotATransaction
        = event.type == nil || ![event.type isEqualToString:BuzzSentryEnvelopeItemTypeTransaction];

    // Transactions have their own sampleRate
    if (eventIsNotATransaction && [self isSampled:self.options.sampleRate]) {
        SENTRY_LOG_DEBUG(@"Event got sampled, will not send the event");
        [self recordLostEvent:kBuzzSentryDataCategoryError reason:kBuzzSentryDiscardReasonSampleRate];
        return nil;
    }

    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    if (nil != infoDict && nil == event.dist) {
        event.dist = infoDict[@"CFBundleVersion"];
    }

    // Use the values from BuzzSentryOptions as a fallback,
    // in case not yet set directly in the event nor in the scope:
    NSString *releaseName = self.options.releaseName;
    if (nil == event.releaseName && nil != releaseName) {
        // If no release was already set (i.e: crashed on an older version) use
        // current release name
        event.releaseName = releaseName;
    }

    NSString *dist = self.options.dist;
    if (nil != dist) {
        event.dist = dist;
    }

    NSString *environment = self.options.environment;
    if (nil != environment && nil == event.environment) {
        // Set the environment from option to the event before Scope is applied
        event.environment = environment;
    }

    [self setSdk:event];

    // We don't want to attach debug meta and stacktraces for transactions;
    if (eventIsNotATransaction) {
        BOOL shouldAttachStacktrace = alwaysAttachStacktrace || self.options.attachStacktrace
            || (nil != event.exceptions && [event.exceptions count] > 0);

        BOOL threadsNotAttached = !(nil != event.threads && event.threads.count > 0);

        if (!isCrashEvent && shouldAttachStacktrace && threadsNotAttached) {
            event.threads = [self.threadInspector getCurrentThreads];
        }

        BOOL debugMetaNotAttached = !(nil != event.debugMeta && event.debugMeta.count > 0);
        if (!isCrashEvent && shouldAttachStacktrace && debugMetaNotAttached
            && event.threads != nil) {
            event.debugMeta = [self.debugImageProvider getDebugImagesForThreads:event.threads];
        }
    }

    event = [scope applyToEvent:event maxBreadcrumb:self.options.maxBreadcrumbs];

    if ([self isOOM:event isCrashEvent:isCrashEvent]) {
        // Remove some mutable properties from the device/app contexts which are no longer
        // applicable
        [self removeExtraDeviceContextFromEvent:event];
    } else {
        // Store the current free memory, free storage, battery level and more mutable properties,
        // at the time of this event
        [self applyExtraDeviceContextToEvent:event];
    }

    [self applyPermissionsToEvent:event];
    [self applyCultureContextToEvent:event];

    // With scope applied, before running callbacks run:
    if (nil == event.environment) {
        // We default to environment 'production' if nothing was set
        event.environment = kSentryDefaultEnvironment;
    }

    // Need to do this after the scope is applied cause this sets the user if there is any
    [self setUserIdIfNoUserSet:event];

    // User can't be nil as setUserIdIfNoUserSet sets it.
    if (self.options.sendDefaultPii && nil == event.user.ipAddress) {
        // Let Sentry infer the IP address from the connection.
        // Due to backward compatibility concerns, Sentry servers set the IP address to {{auto}} out
        // of the box for only Cocoa and JavaScript, which makes this toggle currently somewhat
        // useless. Still, we keep it for future compatibility reasons.
        event.user.ipAddress = @"{{auto}}";
    }

    event = [self callEventProcessors:event];
    if (event == nil) {
        [self recordLost:eventIsNotATransaction reason:kBuzzSentryDiscardReasonEventProcessor];
    }

    if (event != nil && nil != self.options.beforeSend) {
        event = self.options.beforeSend(event);

        if (event == nil) {
            [self recordLost:eventIsNotATransaction reason:kBuzzSentryDiscardReasonBeforeSend];
        }
    }

    if (isCrashEvent && nil != self.options.onCrashedLastRun && !SentrySDK.crashedLastRunCalled) {
        // We only want to call the callback once. It can occur that multiple crash events are
        // about to be sent.
        SentrySDK.crashedLastRunCalled = YES;
        self.options.onCrashedLastRun(event);
    }

    return event;
}

- (BOOL)isSampled:(NSNumber *)sampleRate
{
    if (nil == sampleRate) {
        return NO;
    }

    return [self.random nextNumber] <= sampleRate.doubleValue ? NO : YES;
}

- (BOOL)isDisabled
{
    return !self.options.enabled || nil == self.options.parsedDsn;
}

- (void)logDisabledMessage
{
    SENTRY_LOG_DEBUG(@"SDK disabled or no DSN set. Won't do anyting.");
}

- (BuzzSentryEvent *_Nullable)callEventProcessors:(BuzzSentryEvent *)event
{
    BuzzSentryEvent *newEvent = event;

    for (BuzzSentryEventProcessor processor in SentryGlobalEventProcessor.shared.processors) {
        newEvent = processor(newEvent);
        if (nil == newEvent) {
            SENTRY_LOG_DEBUG(@"BuzzSentryScope callEventProcessors: An event processor decided to "
                             @"remove this event.");
            break;
        }
    }
    return newEvent;
}

- (void)setSdk:(BuzzSentryEvent *)event
{
    if (event.sdk) {
        return;
    }

    id integrations = event.extra[@"__sentry_sdk_integrations"];
    if (!integrations) {
        integrations = [NSMutableArray new];
        for (NSString *integration in SentrySDK.currentHub.installedIntegrationNames) {
            // Every integration starts with "Sentry" and ends with "Integration". To keep the
            // payload of the event small we remove both.
            NSString *withoutSentry = [integration stringByReplacingOccurrencesOfString:@"Sentry"
                                                                             withString:@""];
            NSString *trimmed = [withoutSentry stringByReplacingOccurrencesOfString:@"Integration"
                                                                         withString:@""];
            [integrations addObject:trimmed];
        }

        if (self.options.stitchAsyncCode) {
            [integrations addObject:@"StitchAsyncCode"];
        }
    }

    event.sdk = @{
        @"name" : BuzzSentryMeta.sdkName,
        @"version" : BuzzSentryMeta.versionString,
        @"integrations" : integrations
    };
}

- (void)setUserInfo:(NSDictionary *)userInfo withEvent:(BuzzSentryEvent *)event
{
    if (nil != event && nil != userInfo && userInfo.count > 0) {
        NSMutableDictionary *context;
        if (nil == event.context) {
            context = [[NSMutableDictionary alloc] init];
            event.context = context;
        } else {
            context = [event.context mutableCopy];
        }

        [context setValue:[userInfo sentry_sanitize] forKey:@"user info"];
    }
}

- (void)setUserIdIfNoUserSet:(BuzzSentryEvent *)event
{
    // We only want to set the id if the customer didn't set a user so we at least set something to
    // identify the user.
    if (nil == event.user) {
        BuzzSentryUser *user = [[BuzzSentryUser alloc] init];
        user.userId = [SentryInstallation id];
        event.user = user;
    }
}

- (BOOL)isOOM:(BuzzSentryEvent *)event isCrashEvent:(BOOL)isCrashEvent
{
    if (!isCrashEvent) {
        return NO;
    }

    if (nil == event.exceptions || event.exceptions.count != 1) {
        return NO;
    }

    SentryException *exception = event.exceptions[0];
    return nil != exception.mechanism &&
        [exception.mechanism.type isEqualToString:BuzzSentryOutOfMemoryMechanismType];
}

- (void)applyPermissionsToEvent:(BuzzSentryEvent *)event
{
    [self modifyContext:event
                    key:@"app"
                  block:^(NSMutableDictionary *app) {
                      app[@"permissions"] = @ {
                          @"push_notifications" :
                              [self stringForPermissionStatus:self.permissionsObserver
                                                                  .pushPermissionStatus],
                          @"location_access" :
                              [self stringForPermissionStatus:self.permissionsObserver
                                                                  .locationPermissionStatus],
                          @"photo_library" :
                              [self stringForPermissionStatus:self.permissionsObserver
                                                                  .photoLibraryPermissionStatus],
                      };
                  }];
}

- (NSString *)stringForPermissionStatus:(SentryPermissionStatus)status
{
    switch (status) {
    case kSentryPermissionStatusUnknown:
        return @"unknown";
        break;

    case kSentryPermissionStatusGranted:
        return @"granted";
        break;

    case kSentryPermissionStatusPartial:
        return @"partial";
        break;

    case kSentryPermissionStatusDenied:
        return @"not_granted";
        break;
    }
}

- (void)applyCultureContextToEvent:(BuzzSentryEvent *)event
{
    [self modifyContext:event
                    key:@"culture"
                  block:^(NSMutableDictionary *culture) {
#if TARGET_OS_MACCATALYST
                      if (@available(macCatalyst 13, *)) {
                          culture[@"calendar"] = [self.locale
                              localizedStringForCalendarIdentifier:self.locale.calendarIdentifier];
                          culture[@"display_name"] = [self.locale
                              localizedStringForLocaleIdentifier:self.locale.localeIdentifier];
                      }
#else
            if (@available(iOS 10, macOS 10.12, watchOS 3, tvOS 10, *)) {
                culture[@"calendar"] = [self.locale
                    localizedStringForCalendarIdentifier:self.locale.calendarIdentifier];
                culture[@"display_name"] =
                    [self.locale localizedStringForLocaleIdentifier:self.locale.localeIdentifier];
            }
#endif
                      culture[@"locale"] = self.locale.localeIdentifier;
                      culture[@"is_24_hour_format"] = @(self.locale.sentry_timeIs24HourFormat);
                      culture[@"timezone"] = self.timezone.name;
                  }];
}

- (void)applyExtraDeviceContextToEvent:(BuzzSentryEvent *)event
{
    [self
        modifyContext:event
                  key:@"device"
                block:^(NSMutableDictionary *device) {
                    device[SentryDeviceContextFreeMemoryKey] = @(self.crashWrapper.freeMemorySize);
                    device[@"free_storage"] = @(self.crashWrapper.freeStorageSize);

#if TARGET_OS_IOS
                    if (self.deviceWrapper.orientation != UIDeviceOrientationUnknown) {
                        device[@"orientation"]
                            = UIDeviceOrientationIsPortrait(self.deviceWrapper.orientation)
                            ? @"portrait"
                            : @"landscape";
                    }

                    if (self.deviceWrapper.isBatteryMonitoringEnabled) {
                        device[@"charging"]
                            = self.deviceWrapper.batteryState == UIDeviceBatteryStateCharging
                            ? @(YES)
                            : @(NO);
                        device[@"battery_level"] = @((int)(self.deviceWrapper.batteryLevel * 100));
                    }
#endif
                }];

    [self modifyContext:event
                    key:@"app"
                  block:^(NSMutableDictionary *app) {
                      app[SentryDeviceContextAppMemoryKey] = @(self.crashWrapper.appMemorySize);
                  }];
}

- (void)removeExtraDeviceContextFromEvent:(BuzzSentryEvent *)event
{
    [self modifyContext:event
                    key:@"device"
                  block:^(NSMutableDictionary *device) {
                      [device removeObjectForKey:SentryDeviceContextFreeMemoryKey];
                      [device removeObjectForKey:@"free_storage"];
                      [device removeObjectForKey:@"orientation"];
                      [device removeObjectForKey:@"charging"];
                      [device removeObjectForKey:@"battery_level"];
                  }];

    [self modifyContext:event
                    key:@"app"
                  block:^(NSMutableDictionary *app) {
                      [app removeObjectForKey:SentryDeviceContextAppMemoryKey];
                  }];
}

- (void)modifyContext:(BuzzSentryEvent *)event
                  key:(NSString *)key
                block:(void (^)(NSMutableDictionary *))block
{
    if (nil == event.context || event.context.count == 0) {
        return;
    }

    NSMutableDictionary *context = [[NSMutableDictionary alloc] initWithDictionary:event.context];
    NSMutableDictionary *dict = event.context[key] == nil
        ? [[NSMutableDictionary alloc] init]
        : [[NSMutableDictionary alloc] initWithDictionary:context[key]];
    block(dict);
    context[key] = dict;
    event.context = context;
}

- (void)recordLost:(BOOL)eventIsNotATransaction reason:(BuzzSentryDiscardReason)reason
{
    if (eventIsNotATransaction) {
        [self recordLostEvent:kBuzzSentryDataCategoryError reason:reason];
    } else {
        [self recordLostEvent:kBuzzSentryDataCategoryTransaction reason:reason];
    }
}

- (void)addAttachmentProcessor:(id<BuzzSentryClientAttachmentProcessor>)attachmentProcessor
{
    [self.attachmentProcessors addObject:attachmentProcessor];
}

- (void)removeAttachmentProcessor:(id<BuzzSentryClientAttachmentProcessor>)attachmentProcessor
{
    [self.attachmentProcessors removeObject:attachmentProcessor];
}

@end

NS_ASSUME_NONNULL_END
