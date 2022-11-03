#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(RequestManager)
@protocol BuzzSentryRequestManager <NSObject>

@property (nonatomic, readonly, getter=isReady) BOOL ready;

- (instancetype)initWithSession:(NSURLSession *)session;

- (void)addRequest:(NSURLRequest *)request
    completionHandler:(_Nullable BuzzSentryRequestOperationFinished)completionHandler;

@end

NS_ASSUME_NONNULL_END
