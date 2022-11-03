#import "BuzzSentryQueueableRequestManager.h"
#import "BuzzSentryLog.h"
#import "BuzzSentryRequestOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryQueueableRequestManager ()

@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation BuzzSentryQueueableRequestManager

- (instancetype)initWithSession:(NSURLSession *)session
{
    self = [super init];
    if (self) {
        self.session = session;
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.name = @"io.sentry.QueueableRequestManager.OperationQueue";
        self.queue.maxConcurrentOperationCount = 3;
    }
    return self;
}

- (BOOL)isReady
{
    // We always have at least one operation in the queue when calling this
    return self.queue.operationCount <= 1;
}

- (void)addRequest:(NSURLRequest *)request
    completionHandler:(_Nullable BuzzSentryRequestOperationFinished)completionHandler
{
    BuzzSentryRequestOperation *operation = [[BuzzSentryRequestOperation alloc]
          initWithSession:self.session
                  request:request
        completionHandler:^(NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
            SENTRY_LOG_DEBUG(@"Queued requests: %@", @(self.queue.operationCount - 1));
            if (completionHandler) {
                completionHandler(response, error);
            }
        }];
    [self.queue addOperation:operation];
}

@end

NS_ASSUME_NONNULL_END
