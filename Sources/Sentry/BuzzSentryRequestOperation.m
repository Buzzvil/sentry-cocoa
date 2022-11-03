#import "BuzzSentryRequestOperation.h"
#import "BuzzSentryClient.h"
#import "SentryError.h"
#import "BuzzSentryHub.h"
#import "SentryLog.h"
#import "BuzzSentrySDK+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryRequestOperation ()

@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) NSURLRequest *request;

@end

@implementation BuzzSentryRequestOperation

- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request
              completionHandler:(_Nullable BuzzSentryRequestOperationFinished)completionHandler
{
    self = [super init];
    if (self) {
        self.request = request;
        self.task = [session dataTaskWithRequest:self.request
                               completionHandler:^(NSData *_Nullable data,
                                   NSURLResponse *_Nullable response, NSError *_Nullable error) {
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   NSInteger statusCode = [httpResponse statusCode];

                                   // We only have these if's here because of performance reasons
                                   SENTRY_LOG_DEBUG(@"Request status: %ld", (long)statusCode);
                                   if ([SentrySDK.currentHub getClient].options.debug == YES) {
                                       SENTRY_LOG_DEBUG(@"Request response: %@",
                                           [[NSString alloc] initWithData:data
                                                                 encoding:NSUTF8StringEncoding]);
                                   }

                                   if (nil != error) {
                                       SENTRY_LOG_ERROR(@"Request failed: %@", error);
                                   }

                                   if (completionHandler) {
                                       completionHandler(httpResponse, error);
                                   }

                                   [self completeOperation];
                               }];
    }
    return self;
}

- (void)cancel
{
    if (nil != self.task) {
        [self.task cancel];
    }
    [super cancel];
}

- (void)main
{
    if (nil != self.task) {
        [self.task resume];
    }
}

@end

NS_ASSUME_NONNULL_END
