#import <Foundation/Foundation.h>

#import "BuzzSentryAsynchronousOperation.h"
#import "BuzzSentryQueueableRequestManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface BuzzSentryRequestOperation : BuzzSentryAsynchronousOperation

- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request
              completionHandler:(_Nullable BuzzSentryRequestOperationFinished)completionHandler;

@end

NS_ASSUME_NONNULL_END
