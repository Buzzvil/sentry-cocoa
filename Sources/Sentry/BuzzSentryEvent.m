#import "BuzzSentryEvent.h"
#import "NSDate+BuzzSentryExtras.h"
#import "NSDictionary+BuzzSentrySanitize.h"
#import "BuzzSentryBreadcrumb.h"
#import "BuzzSentryClient.h"
#import "BuzzSentryCurrentDate.h"
#import "BuzzSentryDebugMeta.h"
#import "BuzzSentryException.h"
#import "BuzzSentryId.h"
#import "BuzzSentryLevelMapper.h"
#import "BuzzSentryMessage.h"
#import "BuzzSentryMeta.h"
#import "BuzzSentryStacktrace.h"
#import "BuzzSentryThread.h"
#import "BuzzSentryUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface
BuzzSentryEvent ()

@property (nonatomic) BOOL isCrashEvent;

@end

@implementation BuzzSentryEvent

- (instancetype)init
{
    return [self initWithLevel:kBuzzSentryLevelNone];
}

- (instancetype)initWithLevel:(enum BuzzSentryLevel)level
{
    self = [super init];
    if (self) {
        self.eventId = [[BuzzSentryId alloc] init];
        self.level = level;
        self.platform = @"cocoa";
        self.timestamp = [BuzzSentryCurrentDate date];
    }
    return self;
}

- (instancetype)initWithError:(NSError *)error
{
    self = [self initWithLevel:kBuzzSentryLevelError];
    self.error = error;
    return self;
}

- (NSDictionary<NSString *, id> *)serialize
{
    if (nil == self.timestamp) {
        self.timestamp = [BuzzSentryCurrentDate date];
    }

    NSMutableDictionary *serializedData = @{
        @"event_id" : self.eventId.BuzzSentryIdString,
        @"timestamp" : @(self.timestamp.timeIntervalSince1970),
        @"platform" : @"cocoa",
    }
                                              .mutableCopy;

    if (self.level != kBuzzSentryLevelNone) {
        [serializedData setValue:nameForBuzzSentryLevel(self.level) forKey:@"level"];
    }

    [self addSimpleProperties:serializedData];
    [self addOptionalListProperties:serializedData];

    // This is important here, since we probably use __sentry internal extras
    // before
    [serializedData setValue:[self.extra sentry_sanitize] forKey:@"extra"];
    [serializedData setValue:self.tags forKey:@"tags"];

    return serializedData;
}

- (void)addOptionalListProperties:(NSMutableDictionary *)serializedData
{
    [self addThreads:serializedData];
    [self addExceptions:serializedData];
    [self addDebugImages:serializedData];
}

- (void)addDebugImages:(NSMutableDictionary *)serializedData
{
    NSMutableArray *debugImages = [NSMutableArray new];
    for (BuzzSentryDebugMeta *debugImage in self.debugMeta) {
        [debugImages addObject:[debugImage serialize]];
    }
    if (debugImages.count > 0) {
        [serializedData setValue:@{ @"images" : debugImages } forKey:@"debug_meta"];
    }
}

- (void)addExceptions:(NSMutableDictionary *)serializedData
{
    NSMutableArray *exceptions = [NSMutableArray new];
    for (BuzzSentryException *exception in self.exceptions) {
        [exceptions addObject:[exception serialize]];
    }
    if (exceptions.count > 0) {
        [serializedData setValue:@{ @"values" : exceptions } forKey:@"exception"];
    }
}

- (void)addThreads:(NSMutableDictionary *)serializedData
{
    NSMutableArray *threads = [NSMutableArray new];
    for (BuzzSentryThread *thread in self.threads) {
        [threads addObject:[thread serialize]];
    }
    if (threads.count > 0) {
        [serializedData setValue:@{ @"values" : threads } forKey:@"threads"];
    }
}

- (void)addSimpleProperties:(NSMutableDictionary *)serializedData
{
    [serializedData setValue:[self.sdk sentry_sanitize] forKey:@"sdk"];
    [serializedData setValue:self.releaseName forKey:@"release"];
    [serializedData setValue:self.dist forKey:@"dist"];
    [serializedData setValue:self.environment forKey:@"environment"];

    if (self.transaction) {
        [serializedData setValue:self.transaction forKey:@"transaction"];
    } else if (self.extra[@"__sentry_transaction"]) {
        [serializedData setValue:self.extra[@"__sentry_transaction"] forKey:@"transaction"];
    }

    [serializedData setValue:self.fingerprint forKey:@"fingerprint"];

    [serializedData setValue:[self.user serialize] forKey:@"user"];
    [serializedData setValue:self.modules forKey:@"modules"];

    [serializedData setValue:[self.stacktrace serialize] forKey:@"stacktrace"];

    [serializedData setValue:[self serializeBreadcrumbs] forKey:@"breadcrumbs"];

    [serializedData setValue:[self.context sentry_sanitize] forKey:@"contexts"];

    if (nil != self.message) {
        [serializedData setValue:[self.message serialize] forKey:@"message"];
    }
    [serializedData setValue:self.logger forKey:@"logger"];
    [serializedData setValue:self.serverName forKey:@"server_name"];
    [serializedData setValue:self.type forKey:@"type"];
    if (nil != self.type && [self.type isEqualToString:@"transaction"]) {
        if (nil != self.startTimestamp) {
            [serializedData setValue:@(self.startTimestamp.timeIntervalSince1970)
                              forKey:@"start_timestamp"];
        } else {
            // start timestamp should never be empty
            [serializedData setValue:@(self.timestamp.timeIntervalSince1970)
                              forKey:@"start_timestamp"];
        }
    }
}

- (NSArray *_Nullable)serializeBreadcrumbs
{
    NSMutableArray *crumbs = [NSMutableArray new];
    for (BuzzSentryBreadcrumb *crumb in self.breadcrumbs) {
        [crumbs addObject:[crumb serialize]];
    }
    if (crumbs.count <= 0) {
        return nil;
    }
    return crumbs;
}

@end

NS_ASSUME_NONNULL_END
