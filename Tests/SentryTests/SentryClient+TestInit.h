#import "SentryPermissionsObserver.h"
#import "BuzzSentryRandom.h"
#import "SentryTransport.h"
#import <Sentry/Sentry.h>

@class SentryCrashWrapper, SentryThreadInspector, SentryTransportAdapter, SentryUIDeviceWrapper;

NS_ASSUME_NONNULL_BEGIN

/** Expose the internal test init for testing. */
@interface
BuzzSentryClient (TestInit)

- (_Nullable instancetype)initWithOptions:(BuzzSentryOptions *)options
                      permissionsObserver:(SentryPermissionsObserver *)permissionsObserver;

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
               transportAdapter:(SentryTransportAdapter *)transportAdapter
                    fileManager:(SentryFileManager *)fileManager
                threadInspector:(SentryThreadInspector *)threadInspector
                         random:(id<BuzzSentryRandom>)random
                   crashWrapper:(SentryCrashWrapper *)crashWrapper
            permissionsObserver:(SentryPermissionsObserver *)permissionsObserver
                  deviceWrapper:(SentryUIDeviceWrapper *)deviceWrapper
                         locale:(NSLocale *)locale
                       timezone:(NSTimeZone *)timezone;

@end

NS_ASSUME_NONNULL_END
