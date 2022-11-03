#import "SentryPermissionsObserver.h"
#import "BuzzSentryRandom.h"
#import "BuzzSentryTransport.h"
#import <Sentry/Sentry.h>

@class BuzzSentryCrashWrapper, BuzzSentryThreadInspector, BuzzSentryTransportAdapter, SentryUIDeviceWrapper;

NS_ASSUME_NONNULL_BEGIN

/** Expose the internal test init for testing. */
@interface
BuzzSentryClient (TestInit)

- (_Nullable instancetype)initWithOptions:(BuzzSentryOptions *)options
                      permissionsObserver:(SentryPermissionsObserver *)permissionsObserver;

- (instancetype)initWithOptions:(BuzzSentryOptions *)options
               transportAdapter:(BuzzSentryTransportAdapter *)transportAdapter
                    fileManager:(SentryFileManager *)fileManager
                threadInspector:(BuzzSentryThreadInspector *)threadInspector
                         random:(id<BuzzSentryRandom>)random
                   crashWrapper:(BuzzSentryCrashWrapper *)crashWrapper
            permissionsObserver:(SentryPermissionsObserver *)permissionsObserver
                  deviceWrapper:(SentryUIDeviceWrapper *)deviceWrapper
                         locale:(NSLocale *)locale
                       timezone:(NSTimeZone *)timezone;

@end

NS_ASSUME_NONNULL_END
