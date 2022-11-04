#import "BuzzSentryDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class BuzzSentryUser;

/**
 * An observer to sync the scope to BuzzSentryCrash.
 */
@protocol BuzzSentryScopeObserver <NSObject>

- (void)setUser:(nullable BuzzSentryUser *)user;

- (void)setTags:(nullable NSDictionary<NSString *, NSString *> *)tags;

- (void)setExtras:(nullable NSDictionary<NSString *, id> *)extras;

- (void)setContext:(nullable NSDictionary<NSString *, id> *)context;

- (void)setDist:(nullable NSString *)dist;

- (void)setEnvironment:(nullable NSString *)environment;

- (void)setFingerprint:(nullable NSArray<NSString *> *)fingerprint;

- (void)setLevel:(enum BuzzSentryLevel)level;

- (void)addBreadcrumb:(BuzzSentryBreadcrumb *)crumb;

- (void)clearBreadcrumbs;

- (void)clear;

@end

NS_ASSUME_NONNULL_END