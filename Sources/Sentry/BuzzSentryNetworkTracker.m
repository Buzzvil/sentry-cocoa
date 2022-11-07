#import "BuzzSentryNetworkTracker.h"
#import "BuzzSentryBaggage.h"
#import "BuzzSentryBreadcrumb.h"
#import "BuzzSentryClient+Private.h"
#import "BuzzSentryEvent.h"
#import "BuzzSentryException.h"
#import "BuzzSentryHttpStatusCodeRange+Private.h"
#import "BuzzSentryHttpStatusCodeRange.h"
#import "BuzzSentryHub+Private.h"
#import "BuzzSentryLog.h"
#import "BuzzSentryMechanism.h"
#import "BuzzSentryRequest.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentryScope+Private.h"
#import "BuzzSentrySerialization.h"
#import "BuzzSentryStacktrace.h"
#import "BuzzSentryThread.h"
#import "BuzzSentryThreadInspector.h"
#import "BuzzSentryTraceContext.h"
#import "BuzzSentryTraceHeader.h"
#import "BuzzSentryTracer.h"
#import <objc/runtime.h>

@interface
BuzzSentryNetworkTracker ()

@property (nonatomic, assign) BOOL isNetworkTrackingEnabled;
@property (nonatomic, assign) BOOL isNetworkBreadcrumbEnabled;
@property (nonatomic, assign) BOOL isCaptureFailedRequestsEnabled;

@end

@implementation BuzzSentryNetworkTracker

+ (BuzzSentryNetworkTracker *)sharedInstance
{
    static BuzzSentryNetworkTracker *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _isNetworkTrackingEnabled = NO;
        _isNetworkBreadcrumbEnabled = NO;
        _isCaptureFailedRequestsEnabled = NO;
    }
    return self;
}

- (void)enableNetworkTracking
{
    @synchronized(self) {
        _isNetworkTrackingEnabled = YES;
    }
}

- (void)enableNetworkBreadcrumbs
{
    @synchronized(self) {
        _isNetworkBreadcrumbEnabled = YES;
    }
}

- (void)enableCaptureFailedRequests
{
    @synchronized(self) {
        _isCaptureFailedRequestsEnabled = YES;
    }
}

- (void)disable
{
    @synchronized(self) {
        _isNetworkBreadcrumbEnabled = NO;
        _isNetworkTrackingEnabled = NO;
        _isCaptureFailedRequestsEnabled = NO;
    }
}

- (BOOL)isTargetMatch:(NSURL *)URL withTargets:(NSArray *)targets
{
    for (id targetCheck in targets) {
        if ([targetCheck isKindOfClass:[NSRegularExpression class]]) {
            NSString *string = URL.absoluteString;
            NSUInteger numberOfMatches =
                [targetCheck numberOfMatchesInString:string
                                             options:0
                                               range:NSMakeRange(0, [string length])];
            if (numberOfMatches > 0) {
                return YES;
            }
        } else if ([targetCheck isKindOfClass:[NSString class]]) {
            if ([URL.absoluteString containsString:targetCheck]) {
                return YES;
            }
        }
    }

    return NO;
}

- (void)urlSessionTaskResume:(NSURLSessionTask *)sessionTask
{
    @synchronized(self) {
        if (!self.isNetworkTrackingEnabled) {
            return;
        }
    }

    if (![self isTaskSupported:sessionTask])
        return;

    // SDK not enabled no need to continue
    if (BuzzSentrySDK.options == nil) {
        return;
    }

    NSURL *url = [[sessionTask currentRequest] URL];

    if (url == nil) {
        return;
    }

    // Don't measure requests to Sentry's backend
    NSURL *apiUrl = [NSURL URLWithString:BuzzSentrySDK.options.dsn];
    if ([url.host isEqualToString:apiUrl.host] && [url.path containsString:apiUrl.path]) {
        return;
    }

    @synchronized(sessionTask) {
        if (sessionTask.state == NSURLSessionTaskStateCompleted
            || sessionTask.state == NSURLSessionTaskStateCanceling) {
            return;
        }

        __block id<BuzzSentrySpan> span;
        __block id<BuzzSentrySpan> netSpan;
        netSpan = objc_getAssociatedObject(sessionTask, &SENTRY_NETWORK_REQUEST_TRACKER_SPAN);

        // The task already has a span. Nothing to do.
        if (netSpan != nil) {
            return;
        }

        [BuzzSentrySDK.currentHub.scope useSpan:^(id<BuzzSentrySpan> _Nullable innerSpan) {
            if (innerSpan != nil) {
                span = innerSpan;
                netSpan = [span
                    startChildWithOperation:SENTRY_NETWORK_REQUEST_OPERATION
                                description:[NSString stringWithFormat:@"%@ %@",
                                                      sessionTask.currentRequest.HTTPMethod, url]];
            }
        }];

        // We only create a span if there is a transaction in the scope,
        // otherwise we have nothing else to do here.
        if (netSpan == nil) {
            SENTRY_LOG_DEBUG(@"No transaction bound to scope. Won't track network operation.");
            return;
        }

        if ([sessionTask currentRequest] &&
            [self isTargetMatch:sessionTask.currentRequest.URL
                    withTargets:BuzzSentrySDK.options.tracePropagationTargets]) {
            NSString *baggageHeader = @"";

            BuzzSentryTracer *tracer = [BuzzSentryTracer getTracer:span];
            if (tracer != nil) {
                baggageHeader = [[tracer.traceContext toBaggage]
                    toHTTPHeaderWithOriginalBaggage:
                        [BuzzSentrySerialization
                            decodeBaggage:sessionTask.currentRequest
                                              .allHTTPHeaderFields[SENTRY_BAGGAGE_HEADER]]];
            }

            // First we check if the current request is mutable, so we could easily add a new
            // header. Otherwise we try to change the current request for a new one with the extra
            // header.
            if ([sessionTask.currentRequest isKindOfClass:[NSMutableURLRequest class]]) {
                NSMutableURLRequest *currentRequest
                    = (NSMutableURLRequest *)sessionTask.currentRequest;
                [currentRequest setValue:[netSpan toTraceHeader].value
                      forHTTPHeaderField:SENTRY_TRACE_HEADER];

                if (baggageHeader.length > 0) {
                    [currentRequest setValue:baggageHeader
                          forHTTPHeaderField:SENTRY_BAGGAGE_HEADER];
                }
            } else {
                // Even though NSURLSessionTask doesn't have 'setCurrentRequest', some subclasses
                // do. For those subclasses we replace the currentRequest with a mutable one with
                // the additional trace header. Since NSURLSessionTask is a public class and can be
                // override, we believe this is not considered a private api.
                SEL setCurrentRequestSelector = NSSelectorFromString(@"setCurrentRequest:");
                if ([sessionTask respondsToSelector:setCurrentRequestSelector]) {
                    NSMutableURLRequest *newRequest = [sessionTask.currentRequest mutableCopy];

                    [newRequest setValue:[netSpan toTraceHeader].value
                        forHTTPHeaderField:SENTRY_TRACE_HEADER];

                    if (baggageHeader.length > 0) {
                        [newRequest setValue:baggageHeader
                            forHTTPHeaderField:SENTRY_BAGGAGE_HEADER];
                    }

                    void (*func)(id, SEL, id param)
                        = (void *)[sessionTask methodForSelector:setCurrentRequestSelector];
                    func(sessionTask, setCurrentRequestSelector, newRequest);
                }
            }
        } else {
            SENTRY_LOG_DEBUG(@"Not adding trace_id and baggage headers for %@",
                sessionTask.currentRequest.URL.absoluteString);
        }

        SENTRY_LOG_DEBUG(
            @"BuzzSentryNetworkTracker automatically started HTTP span for sessionTask: %@",
            netSpan.description);

        objc_setAssociatedObject(sessionTask, &SENTRY_NETWORK_REQUEST_TRACKER_SPAN, netSpan,
            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)urlSessionTask:(NSURLSessionTask *)sessionTask setState:(NSURLSessionTaskState)newState
{
    if (!self.isNetworkTrackingEnabled && !self.isNetworkBreadcrumbEnabled
        && !self.isCaptureFailedRequestsEnabled) {
        return;
    }

    if (![self isTaskSupported:sessionTask]) {
        return;
    }

    if (newState == NSURLSessionTaskStateRunning) {
        return;
    }

    NSURL *url = [[sessionTask currentRequest] URL];

    if (url == nil) {
        return;
    }

    // Don't measure requests to Sentry's backend
    NSURL *apiUrl = [NSURL URLWithString:BuzzSentrySDK.options.dsn];
    if ([url.host isEqualToString:apiUrl.host] && [url.path containsString:apiUrl.path]) {
        return;
    }

    id<BuzzSentrySpan> netSpan;
    @synchronized(sessionTask) {
        netSpan = objc_getAssociatedObject(sessionTask, &SENTRY_NETWORK_REQUEST_TRACKER_SPAN);
        // We'll just go through once
        objc_setAssociatedObject(sessionTask, &SENTRY_NETWORK_REQUEST_TRACKER_SPAN, nil,
            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (sessionTask.state == NSURLSessionTaskStateRunning) {
        [self captureFailedRequests:sessionTask];

        [self addBreadcrumbForSessionTask:sessionTask];

        NSInteger responseStatusCode = [self urlResponseStatusCode:sessionTask.response];

        if (responseStatusCode != -1) {
            NSNumber *statusCode = [NSNumber numberWithInteger:responseStatusCode];

            if (netSpan != nil) {
                [netSpan setTagValue:[NSString stringWithFormat:@"%@", statusCode]
                              forKey:@"http.status_code"];
            }
        }
    }

    if (netSpan == nil) {
        return;
    }

    [netSpan setDataValue:sessionTask.currentRequest.HTTPMethod forKey:@"method"];
    [netSpan setDataValue:sessionTask.currentRequest.URL.path forKey:@"url"];
    [netSpan setDataValue:@"fetch" forKey:@"type"];

    [netSpan finishWithStatus:[self statusForSessionTask:sessionTask state:newState]];
    SENTRY_LOG_DEBUG(@"BuzzSentryNetworkTracker finished HTTP span for sessionTask");
}

- (void)captureFailedRequests:(NSURLSessionTask *)sessionTask
{
    if (!self.isCaptureFailedRequestsEnabled) {
        SENTRY_LOG_DEBUG(
            @"captureFailedRequestsEnabled is disabled, not capturing HTTP Client errors.");
        return;
    }

    // if request or response are null, we can't raise the event
    if (sessionTask.currentRequest == nil || sessionTask.response == nil) {
        SENTRY_LOG_DEBUG(@"Request or Response are null, not capturing HTTP Client errors.");
        return;
    }
    // some properties are only available if the response is of the NSHTTPURLResponse type
    // bail if not
    if (![sessionTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
        SENTRY_LOG_DEBUG(@"Response isn't a known type, not capturing HTTP Client errors.");
        return;
    }
    NSHTTPURLResponse *myResponse = (NSHTTPURLResponse *)sessionTask.response;
    NSURLRequest *myRequest = sessionTask.currentRequest;
    NSNumber *responseStatusCode = @(myResponse.statusCode);

    if (![self containsStatusCode:myResponse.statusCode]) {
        SENTRY_LOG_DEBUG(@"Response status code isn't within the allowed ranges, not capturing "
                         @"HTTP Client errors.");
        return;
    }

    if (![self isTargetMatch:myRequest.URL withTargets:BuzzSentrySDK.options.failedRequestTargets]) {
        SENTRY_LOG_DEBUG(
            @"Request url isn't within the request targets, not capturing HTTP Client errors.");
        return;
    }

    NSString *message = [NSString
        stringWithFormat:@"HTTP Client Error with status code: %ld", (long)myResponse.statusCode];

    BuzzSentryEvent *event = [[BuzzSentryEvent alloc] initWithLevel:kBuzzSentryLevelError];

    BuzzSentryThreadInspector *threadInspector = BuzzSentrySDK.currentHub.getClient.threadInspector;
    NSArray<BuzzSentryThread *> *threads = [threadInspector getCurrentThreads];

    // sessionTask.error isn't used because it's not about network errors but rather
    // requests that are considered failed depending on the HTTP status code
    BuzzSentryException *sentryException = [[BuzzSentryException alloc] initWithValue:message
                                                                         type:@"HTTPClientError"];
    sentryException.mechanism = [[BuzzSentryMechanism alloc] initWithType:@"HTTPClientError"];

    for (BuzzSentryThread *thread in threads) {
        if ([thread.current boolValue]) {
            BuzzSentryStacktrace *sentryStacktrace = [thread stacktrace];
            sentryStacktrace.snapshot = @(YES);

            sentryException.stacktrace = sentryStacktrace;

            break;
        }
    }

    BuzzSentryRequest *request = [[BuzzSentryRequest alloc] init];

    NSURL *url = [[sessionTask currentRequest] URL];

    NSString *urlString = [NSString stringWithFormat:@"%@://%@%@", url.scheme, url.host, url.path];

    request.url = urlString;
    request.method = myRequest.HTTPMethod;
    request.fragment = url.fragment;
    request.queryString = url.query;
    request.bodySize = [NSNumber numberWithLongLong:sessionTask.countOfBytesSent];
    if (nil != myRequest.allHTTPHeaderFields) {
        NSDictionary<NSString *, NSString *> *headers = myRequest.allHTTPHeaderFields.copy;
        request.headers = headers;
        request.cookies = headers[@"Cookie"];
    }

    event.exceptions = @[ sentryException ];
    event.request = request;

    NSMutableDictionary<NSString *, id> *context = [[NSMutableDictionary alloc] init];
    NSMutableDictionary<NSString *, id> *response = [[NSMutableDictionary alloc] init];

    [response setValue:responseStatusCode forKey:@"status_code"];
    if (nil != myResponse.allHeaderFields) {
        NSDictionary<NSString *, NSString *> *headers = myResponse.allHeaderFields.copy;
        [response setValue:headers forKey:@"headers"];
        [response setValue:headers[@"Set-Cookie"] forKey:@"cookies"];
    }
    if (sessionTask.countOfBytesReceived != 0) {
        [response setValue:[NSNumber numberWithLongLong:sessionTask.countOfBytesReceived]
                    forKey:@"body_size"];
    }

    context[@"response"] = response;
    event.context = context;

    [BuzzSentrySDK captureEvent:event];
}

- (BOOL)containsStatusCode:(NSInteger)statusCode
{
    for (BuzzSentryHttpStatusCodeRange *range in BuzzSentrySDK.options.failedRequestStatusCodes) {
        if ([range isInRange:statusCode]) {
            return YES;
        }
    }

    return NO;
}

- (void)addBreadcrumbForSessionTask:(NSURLSessionTask *)sessionTask
{
    if (!self.isNetworkBreadcrumbEnabled) {
        return;
    }

    BuzzSentryLevel breadcrumbLevel = sessionTask.error != nil ? kBuzzSentryLevelError : kBuzzSentryLevelInfo;
    BuzzSentryBreadcrumb *breadcrumb = [[BuzzSentryBreadcrumb alloc] initWithLevel:breadcrumbLevel
                                                                  category:@"http"];
    breadcrumb.type = @"http";
    NSMutableDictionary<NSString *, id> *breadcrumbData = [NSMutableDictionary new];
    breadcrumbData[@"url"] = sessionTask.currentRequest.URL.absoluteString;
    breadcrumbData[@"method"] = sessionTask.currentRequest.HTTPMethod;
    breadcrumbData[@"request_body_size"] =
        [NSNumber numberWithLongLong:sessionTask.countOfBytesSent];
    breadcrumbData[@"response_body_size"] =
        [NSNumber numberWithLongLong:sessionTask.countOfBytesReceived];

    NSInteger responseStatusCode = [self urlResponseStatusCode:sessionTask.response];

    if (responseStatusCode != -1) {
        NSNumber *statusCode = [NSNumber numberWithInteger:responseStatusCode];
        breadcrumbData[@"status_code"] = statusCode;
        breadcrumbData[@"reason"] =
            [NSHTTPURLResponse localizedStringForStatusCode:responseStatusCode];
    }

    breadcrumb.data = breadcrumbData;
    [BuzzSentrySDK addBreadcrumb:breadcrumb];
}

- (NSInteger)urlResponseStatusCode:(NSURLResponse *)response
{
    if (response != nil && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        return ((NSHTTPURLResponse *)response).statusCode;
    }
    return -1;
}

- (BuzzSentrySpanStatus)statusForSessionTask:(NSURLSessionTask *)task state:(NSURLSessionTaskState)state
{
    switch (state) {
    case NSURLSessionTaskStateSuspended:
        return kBuzzSentrySpanStatusAborted;
    case NSURLSessionTaskStateCanceling:
        return kBuzzSentrySpanStatusCancelled;
    case NSURLSessionTaskStateCompleted:
        return task.error != nil
            ? kBuzzSentrySpanStatusUnknownError
            : [self spanStatusForHttpResponseStatusCode:[self urlResponseStatusCode:task.response]];
    case NSURLSessionTaskStateRunning:
        break;
    }
    return kBuzzSentrySpanStatusUndefined;
}

- (BOOL)isTaskSupported:(NSURLSessionTask *)task
{
    // Since streams are usually created to stay connected we don't measure this type of data
    // transfer.
    return [task isKindOfClass:[NSURLSessionDataTask class]] ||
        [task isKindOfClass:[NSURLSessionDownloadTask class]] ||
        [task isKindOfClass:[NSURLSessionUploadTask class]];
}

// https://develop.sentry.dev/sdk/event-payloads/span/
- (BuzzSentrySpanStatus)spanStatusForHttpResponseStatusCode:(NSInteger)statusCode
{
    if (statusCode >= 200 && statusCode < 300) {
        return kBuzzSentrySpanStatusOk;
    }

    switch (statusCode) {
    case 400:
        return kBuzzSentrySpanStatusInvalidArgument;
    case 401:
        return kBuzzSentrySpanStatusUnauthenticated;
    case 403:
        return kBuzzSentrySpanStatusPermissionDenied;
    case 404:
        return kBuzzSentrySpanStatusNotFound;
    case 409:
        return kBuzzSentrySpanStatusAborted;
    case 429:
        return kBuzzSentrySpanStatusResourceExhausted;
    case 500:
        return kBuzzSentrySpanStatusInternalError;
    case 501:
        return kBuzzSentrySpanStatusUnimplemented;
    case 503:
        return kBuzzSentrySpanStatusUnavailable;
    case 504:
        return kBuzzSentrySpanStatusDeadlineExceeded;
    }
    return kBuzzSentrySpanStatusUndefined;
}

@end
