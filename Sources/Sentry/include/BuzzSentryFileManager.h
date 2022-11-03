#import "BuzzSentryCurrentDateProvider.h"
#import "BuzzSentryDataCategory.h"
#import "BuzzSentryDefines.h"
#import "BuzzSentrySession.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BuzzSentryFileManagerDelegate;

@class BuzzSentryEvent, BuzzSentryOptions, BuzzSentryEnvelope, BuzzSentryFileContents, BuzzSentryAppState,
    BuzzSentryDispatchQueueWrapper;

NS_SWIFT_NAME(BuzzSentryFileManager)
@interface BuzzSentryFileManager : NSObject
SENTRY_NO_INIT

@property (nonatomic, readonly) NSString *sentryPath;

- (nullable instancetype)initWithOptions:(BuzzSentryOptions *)options
                  andCurrentDateProvider:(id<BuzzSentryCurrentDateProvider>)currentDateProvider
                                   error:(NSError **)error;

- (nullable instancetype)initWithOptions:(BuzzSentryOptions *)options
                  andCurrentDateProvider:(id<BuzzSentryCurrentDateProvider>)currentDateProvider
                    dispatchQueueWrapper:(BuzzSentryDispatchQueueWrapper *)dispatchQueueWrapper
                                   error:(NSError **)error NS_DESIGNATED_INITIALIZER;

- (void)setDelegate:(id<BuzzSentryFileManagerDelegate>)delegate;

- (NSString *)storeEnvelope:(BuzzSentryEnvelope *)envelope;

- (void)storeCurrentSession:(BuzzSentrySession *)session;
- (void)storeCrashedSession:(BuzzSentrySession *)session;
- (BuzzSentrySession *_Nullable)readCurrentSession;
- (BuzzSentrySession *_Nullable)readCrashedSession;
- (void)deleteCurrentSession;
- (void)deleteCrashedSession;

- (void)storeTimestampLastInForeground:(NSDate *)timestamp;
- (NSDate *_Nullable)readTimestampLastInForeground;
- (void)deleteTimestampLastInForeground;

+ (BOOL)createDirectoryAtPath:(NSString *)path withError:(NSError **)error;

- (void)deleteAllEnvelopes;
- (void)deleteAllFolders;

/**
 * Get all envelopes sorted ascending by the timeIntervalSince1970 the envelope was stored and if
 * two envelopes are stored at the same time sorted by the order they were stored.
 */
- (NSArray<BuzzSentryFileContents *> *)getAllEnvelopes;

/**
 * Gets the oldest stored envelope. For the order see getAllEnvelopes.
 *
 * @return SentryFileContens if there is an envelope and nil if there are no envelopes.
 */
- (BuzzSentryFileContents *_Nullable)getOldestEnvelope;

- (BOOL)removeFileAtPath:(NSString *)path;

- (NSArray<NSString *> *)allFilesInFolder:(NSString *)path;

- (NSString *)storeDictionary:(NSDictionary *)dictionary toPath:(NSString *)path;

- (void)storeAppState:(BuzzSentryAppState *)appState;
- (void)moveAppStateToPreviousAppState;
- (BuzzSentryAppState *_Nullable)readAppState;
- (BuzzSentryAppState *_Nullable)readPreviousAppState;
- (void)deleteAppState;

- (NSNumber *_Nullable)readTimezoneOffset;
- (void)storeTimezoneOffset:(NSInteger)offset;
- (void)deleteTimezoneOffset;

@end

@protocol BuzzSentryFileManagerDelegate <NSObject>

- (void)envelopeItemDeleted:(BuzzSentryDataCategory)dataCategory;

@end

NS_ASSUME_NONNULL_END
