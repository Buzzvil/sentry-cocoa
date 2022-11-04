#import <Foundation/Foundation.h>

#import <BuzzSentry/BuzzSentryDefines.h>
#import <BuzzSentry/BuzzSentrySerializable.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Breadcrumb)
@interface BuzzSentryBreadcrumb : NSObject <BuzzSentrySerializable>

/**
 * Level of breadcrumb
 */
@property (nonatomic) SentryLevel level;

/**
 * Category of bookmark, can be any string
 */
@property (nonatomic, copy) NSString *category;

/**
 * NSDate when the breadcrumb happened
 */
@property (nonatomic, strong) NSDate *_Nullable timestamp;

/**
 * Type of breadcrumb, can be e.g.: http, empty, user, navigation
 * This will be used as icon of the breadcrumb
 */
@property (nonatomic, copy) NSString *_Nullable type;

/**
 * Message for the breadcrumb
 */
@property (nonatomic, copy) NSString *_Nullable message;

/**
 * Arbitrary additional data that will be sent with the breadcrumb
 */
@property (nonatomic, strong) NSDictionary<NSString *, id> *_Nullable data;

/**
 * Initializer for BuzzSentryBreadcrumb
 *
 * @param level SentryLevel
 * @param category String
 * @return BuzzSentryBreadcrumb
 */
- (instancetype)initWithLevel:(SentryLevel)level category:(NSString *)category;
- (instancetype)init;
+ (instancetype)new NS_UNAVAILABLE;

- (NSDictionary<NSString *, id> *)serialize;

- (BOOL)isEqual:(id _Nullable)other;

- (BOOL)isEqualToBreadcrumb:(BuzzSentryBreadcrumb *)breadcrumb;

- (NSUInteger)hash;

@end

NS_ASSUME_NONNULL_END
