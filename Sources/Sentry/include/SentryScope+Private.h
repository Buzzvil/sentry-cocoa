#import <Foundation/Foundation.h>

#import "SentryScope.h"
#import "BuzzSentryScopeObserver.h"

@class BuzzSentryAttachment;

NS_ASSUME_NONNULL_BEGIN

@interface
SentryScope (Private)

@property (atomic, copy, readonly, nullable) NSString *environmentString;

@property (atomic, strong, readonly) NSArray<BuzzSentryAttachment *> *attachments;

@property (atomic, strong) BuzzSentryUser *_Nullable userObject;

@property (atomic, strong)
    NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *contextDictionary;

- (void)addObserver:(id<BuzzSentryScopeObserver>)observer;

@end

NS_ASSUME_NONNULL_END
