#import "BuzzSentryLevelMapper.h"
#import <Foundation/Foundation.h>
#import <NSData+BuzzSentry.h>
#import <BuzzSentryBreadcrumb.h>
#import <BuzzSentryCrashJSONCodec.h>
#import <BuzzSentryCrashJSONCodecObjC.h>
#import <BuzzSentryCrashScopeObserver.h>
#import <BuzzSentryLog.h>
#import <BuzzSentryScopeSyncC.h>
#import <BuzzSentryUser.h>

@interface
BuzzSentryCrashScopeObserver ()

@end

@implementation BuzzSentryCrashScopeObserver

- (instancetype)initWithMaxBreadcrumbs:(NSInteger)maxBreadcrumbs
{
    if (self = [super init]) {
        sentrycrash_scopesync_configureBreadcrumbs(maxBreadcrumbs);
    }

    return self;
}

- (void)setUser:(nullable BuzzSentryUser *)user
{
    [self syncScope:user
        serialize:^{ return [user serialize]; }
        syncToBuzzSentryCrash:^(const void *bytes) { sentrycrash_scopesync_setUser(bytes); }];
}

- (void)setDist:(nullable NSString *)dist
{
    [self syncScope:dist
        serialize:^{ return dist; }
        syncToBuzzSentryCrash:^(const void *bytes) { sentrycrash_scopesync_setDist(bytes); }];
}

- (void)setEnvironment:(nullable NSString *)environment
{
    [self syncScope:environment
        serialize:^{ return environment; }
        syncToBuzzSentryCrash:^(const void *bytes) { sentrycrash_scopesync_setEnvironment(bytes); }];
}

- (void)setContext:(nullable NSDictionary<NSString *, id> *)context
{
    [self syncScope:context
        syncToBuzzSentryCrash:^(const void *bytes) { sentrycrash_scopesync_setContext(bytes); }];
}

- (void)setExtras:(nullable NSDictionary<NSString *, id> *)extras
{
    [self syncScope:extras
        syncToBuzzSentryCrash:^(const void *bytes) { sentrycrash_scopesync_setExtras(bytes); }];
}

- (void)setTags:(nullable NSDictionary<NSString *, NSString *> *)tags
{
    [self syncScope:tags
        syncToBuzzSentryCrash:^(const void *bytes) { sentrycrash_scopesync_setTags(bytes); }];
}

- (void)setFingerprint:(nullable NSArray<NSString *> *)fingerprint
{
    [self syncScope:fingerprint
        serialize:^{
            NSArray *result = nil;
            if (fingerprint.count > 0) {
                result = fingerprint;
            }
            return result;
        }
        syncToBuzzSentryCrash:^(const void *bytes) { sentrycrash_scopesync_setFingerprint(bytes); }];
}

- (void)setLevel:(enum BuzzSentryLevel)level
{
    if (level == kBuzzSentryLevelNone) {
        sentrycrash_scopesync_setLevel(NULL);
        return;
    }

    NSString *levelAsString = nameForBuzzSentryLevel(level);
    NSData *json = [self toJSONEncodedCString:levelAsString];

    sentrycrash_scopesync_setLevel([json bytes]);
}

- (void)addBreadcrumb:(BuzzSentryBreadcrumb *)crumb
{
    NSDictionary *serialized = [crumb serialize];
    NSData *json = [self toJSONEncodedCString:serialized];
    if (json == nil) {
        return;
    }

    sentrycrash_scopesync_addBreadcrumb([json bytes]);
}

- (void)clearBreadcrumbs
{
    sentrycrash_scopesync_clearBreadcrumbs();
}

- (void)clear
{
    sentrycrash_scopesync_clear();
}

- (void)syncScope:(NSDictionary *)dict syncToBuzzSentryCrash:(void (^)(const void *))syncToBuzzSentryCrash
{
    [self syncScope:dict
                serialize:^{
                    NSDictionary *result = nil;
                    if (dict.count > 0) {
                        result = dict;
                    }
                    return result;
                }
        syncToBuzzSentryCrash:syncToBuzzSentryCrash];
}

- (void)syncScope:(id)object
            serialize:(nullable id (^)(void))serialize
    syncToBuzzSentryCrash:(void (^)(const void *))syncToBuzzSentryCrash
{
    if (object == nil) {
        syncToBuzzSentryCrash(NULL);
        return;
    }

    id serialized = serialize();
    if (serialized == nil) {
        syncToBuzzSentryCrash(NULL);
        return;
    }

    NSData *jsonEncodedCString = [self toJSONEncodedCString:serialized];
    if (jsonEncodedCString == nil) {
        return;
    }

    syncToBuzzSentryCrash([jsonEncodedCString bytes]);
}

- (nullable NSData *)toJSONEncodedCString:(id)toSerialize
{
    NSError *error = nil;
    NSData *json = nil;
    if (toSerialize != nil) {
        json = [BuzzSentryCrashJSONCodec encode:toSerialize
                                    options:BuzzSentryCrashJSONEncodeOptionSorted
                                      error:&error];
        if (error != nil) {
            SENTRY_LOG_ERROR(@"Could not serialize %@", error);
            return nil;
        }
    }

    // C strings need to be null terminated
    return [json sentry_nullTerminated];
}

@end