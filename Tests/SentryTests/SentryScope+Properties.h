#import <Sentry/Sentry.h>

NS_ASSUME_NONNULL_BEGIN

/** Expose the internal properties for testing. */
@interface
BuzzSentryScope (Properties)

@property (atomic, strong) BuzzSentryUser *_Nullable userObject;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *_Nullable tagDictionary;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *_Nullable extraDictionary;
@property (nonatomic, strong)
    NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *_Nullable contextDictionary;
@property (nonatomic, strong) NSMutableArray<BuzzSentryBreadcrumb *> *breadcrumbArray;
@property (atomic, copy) NSString *_Nullable distString;
@property (atomic, copy) NSString *_Nullable environmentString;
@property (atomic, strong) NSArray<NSString *> *_Nullable fingerprintArray;
@property (atomic) enum SentryLevel levelEnum;
@property (atomic) NSInteger maxBreadcrumbs;
@property (atomic, strong) NSMutableArray<BuzzSentryAttachment *> *attachmentArray;

@end

NS_ASSUME_NONNULL_END
