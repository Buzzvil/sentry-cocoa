#import "BuzzSentryProfiler.h"

#if SENTRY_TARGET_PROFILING_SUPPORTED
#    import "NSDate+BuzzSentryExtras.h"
#    import "BuzzSentryBacktrace.hpp"
#    import "BuzzSentryClient+Private.h"
#    import "BuzzSentryCurrentDate.h"
#    import "BuzzSentryDebugImageProvider.h"
#    import "BuzzSentryDebugMeta.h"
#    import "BuzzSentryDefines.h"
#    import "BuzzSentryDependencyContainer.h"
#    import "BuzzSentryDevice.h"
#    import "BuzzSentryEnvelope.h"
#    import "BuzzSentryEnvelopeItemType.h"
#    import "BuzzSentryFramesTracker.h"
#    import "BuzzSentryHexAddressFormatter.h"
#    import "BuzzSentryHub+Private.h"
#    import "BuzzSentryId.h"
#    import "BuzzSentryLog.h"
#    import "BuzzSentrySamplingProfiler.hpp"
#    import "BuzzSentryScope+Private.h"
#    import "BuzzSentryScreenFrames.h"
#    import "BuzzSentrySerialization.h"
#    import "BuzzSentrySpanId.h"
#    import "BuzzSentryThread.h"
#    import "BuzzSentryTime.h"
#    import "BuzzSentryTransaction.h"
#    import "BuzzSentryTransactionContext.h"
#    import "BuzzSentryTransactionContext+Private.h"

#    if defined(DEBUG)
#        include <execinfo.h>
#    endif

#    import <cstdint>
#    import <memory>

#    if TARGET_OS_IOS
#        import <UIKit/UIKit.h>
#    endif

const int kBuzzSentryProfilerFrequencyHz = 101;
NSString *const kTestStringConst = @"test";

using namespace sentry::profiling;

NSString *
parseBacktraceSymbolsFunctionName(const char *symbol)
{
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression
            regularExpressionWithPattern:@"\\d+\\s+\\S+\\s+0[xX][0-9a-fA-F]+\\s+(.+)\\s+\\+\\s+\\d+"
                                 options:0
                                   error:nil];
    });
    const auto symbolNSStr = [NSString stringWithUTF8String:symbol];
    const auto match = [regex firstMatchInString:symbolNSStr
                                         options:0
                                           range:NSMakeRange(0, [symbolNSStr length])];
    if (match == nil) {
        return symbolNSStr;
    }
    return [symbolNSStr substringWithRange:[match rangeAtIndex:1]];
}

std::mutex _gProfilerLock;
NSMutableDictionary<BuzzSentrySpanId *, BuzzSentryProfiler *> *_gProfilersPerSpanID;
BuzzSentryProfiler *_Nullable _gCurrentProfiler;

NSString *
profilerTruncationReasonName(BuzzSentryProfilerTruncationReason reason)
{
    switch (reason) {
    case BuzzSentryProfilerTruncationReasonNormal:
        return @"normal";
    case BuzzSentryProfilerTruncationReasonAppMovedToBackground:
        return @"backgrounded";
    case BuzzSentryProfilerTruncationReasonTimeout:
        return @"timeout";
    }
}

@implementation BuzzSentryProfiler {
    NSMutableDictionary<NSString *, id> *_profile;
    uint64_t _startTimestamp;
    NSDate *_startDate;
    uint64_t _endTimestamp;
    NSDate *_endDate;
    std::shared_ptr<SamplingProfiler> _profiler;
    BuzzSentryDebugImageProvider *_debugImageProvider;
    thread::TIDType _mainThreadID;

    NSMutableArray<BuzzSentrySpanId *> *_spansInFlight;
    NSMutableArray<BuzzSentryTransaction *> *_transactions;
    BuzzSentryProfilerTruncationReason _truncationReason;
    BuzzSentryScreenFrames *_frameInfo;
    NSTimer *_timeoutTimer;
    BuzzSentryHub *__weak _hub;
}

+ (void)initialize
{
#    if SENTRY_TARGET_PROFILING_SUPPORTED
    if (self == [BuzzSentryProfiler class]) {
        _gProfilersPerSpanID = [NSMutableDictionary<BuzzSentrySpanId *, BuzzSentryProfiler *> dictionary];
    }
#    endif // SENTRY_TARGET_PROFILING_SUPPORTED
}

#    if SENTRY_TARGET_PROFILING_SUPPORTED
- (instancetype)init
{
    if (!(self = [super init])) {
        return nil;
    }

    SENTRY_LOG_DEBUG(@"Initialized new BuzzSentryProfiler %@", self);
    _debugImageProvider = [BuzzSentryDependencyContainer sharedInstance].debugImageProvider;
    _mainThreadID = ThreadHandle::current()->tid();
    _spansInFlight = [NSMutableArray<BuzzSentrySpanId *> array];
    _transactions = [NSMutableArray<BuzzSentryTransaction *> array];
    return self;
}
#    endif

#    pragma mark - Public

+ (void)startForSpanID:(BuzzSentrySpanId *)spanID hub:(BuzzSentryHub *)hub
{
#    if SENTRY_TARGET_PROFILING_SUPPORTED
    NSTimeInterval timeoutInterval = 30;
#        if defined(TEST) || defined(TESTCI)
    timeoutInterval = 1;
#        endif
    [self startForSpanID:spanID hub:hub timeoutInterval:timeoutInterval];
#    endif
}

+ (void)startForSpanID:(BuzzSentrySpanId *)spanID
                   hub:(BuzzSentryHub *)hub
       timeoutInterval:(NSTimeInterval)timeoutInterval
{
#    if SENTRY_TARGET_PROFILING_SUPPORTED
    std::lock_guard<std::mutex> l(_gProfilerLock);

    if (_gCurrentProfiler == nil) {
        _gCurrentProfiler = [[BuzzSentryProfiler alloc] init];
        if (_gCurrentProfiler == nil) {
            SENTRY_LOG_WARN(@"Profiler was not initialized, will not proceed.");
            return;
        }
#        if SENTRY_HAS_UIKIT
        [BuzzSentryFramesTracker.sharedInstance resetProfilingTimestamps];
#        endif // SENTRY_HAS_UIKIT
        [_gCurrentProfiler start];
        _gCurrentProfiler->_timeoutTimer =
            [NSTimer scheduledTimerWithTimeInterval:timeoutInterval
                                             target:self
                                           selector:@selector(timeoutAbort)
                                           userInfo:nil
                                            repeats:NO];
#        if SENTRY_HAS_UIKIT
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundAbort)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
#        endif // SENTRY_HAS_UIKIT
        _gCurrentProfiler->_hub = hub;
    }

    SENTRY_LOG_DEBUG(
        @"Tracking span with ID %@ with profiler %@", spanID.buzzSentrySpanIdString, _gCurrentProfiler);
    [_gCurrentProfiler->_spansInFlight addObject:spanID];
    _gProfilersPerSpanID[spanID] = _gCurrentProfiler;
#    endif // SENTRY_TARGET_PROFILING_SUPPORTED
}

+ (void)stopProfilingSpan:(id<BuzzSentrySpan>)span
{
#    if SENTRY_TARGET_PROFILING_SUPPORTED
    std::lock_guard<std::mutex> l(_gProfilerLock);

    if (_gCurrentProfiler == nil) {
        SENTRY_LOG_DEBUG(
            @"No profiler tracking span with id %@", span.context.spanId.buzzSentrySpanIdString);
        return;
    }

    [_gCurrentProfiler->_spansInFlight removeObject:span.context.spanId];
    if (_gCurrentProfiler->_spansInFlight.count == 0) {
        SENTRY_LOG_DEBUG(@"Stopping profiler %@ because span with id %@ was last being profiled.",
            _gCurrentProfiler, span.context.spanId.buzzSentrySpanIdString);
        [self stopProfilerForReason:BuzzSentryProfilerTruncationReasonNormal];
    }
#    endif // SENTRY_TARGET_PROFILING_SUPPORTED
}

+ (void)dropTransaction:(BuzzSentryTransaction *)transaction
{
#    if SENTRY_TARGET_PROFILING_SUPPORTED
    std::lock_guard<std::mutex> l(_gProfilerLock);

    const auto spanID = transaction.trace.context.spanId;
    const auto profiler = _gProfilersPerSpanID[spanID];
    if (profiler == nil) {
        SENTRY_LOG_DEBUG(@"No profiler tracking span with id %@", spanID.buzzSentrySpanIdString);
        return;
    }

    [self captureEnvelopeIfFinished:profiler spanID:spanID];
#    endif // SENTRY_TARGET_PROFILING_SUPPORTED
}

+ (void)linkTransaction:(BuzzSentryTransaction *)transaction
{
#    if SENTRY_TARGET_PROFILING_SUPPORTED
    std::lock_guard<std::mutex> l(_gProfilerLock);

    const auto spanID = transaction.trace.context.spanId;
    BuzzSentryProfiler *profiler = _gProfilersPerSpanID[spanID];
    if (profiler == nil) {
        SENTRY_LOG_DEBUG(@"No profiler tracking span with id %@", spanID.buzzSentrySpanIdString);
        return;
    }

    SENTRY_LOG_DEBUG(@"Found profiler waiting for span with ID %@: %@",
        transaction.trace.context.spanId.buzzSentrySpanIdString, profiler);
    [profiler addTransaction:transaction];

    [self captureEnvelopeIfFinished:profiler spanID:spanID];
#    endif // SENTRY_TARGET_PROFILING_SUPPORTED
}

+ (BOOL)isRunning
{
#    if SENTRY_TARGET_PROFILING_SUPPORTED
    std::lock_guard<std::mutex> l(_gProfilerLock);
    return [_gCurrentProfiler isRunning];
#    endif // SENTRY_TARGET_PROFILING_SUPPORTED
}

#    pragma mark - Private

+ (void)captureEnvelopeIfFinished:(BuzzSentryProfiler *)profiler spanID:(BuzzSentrySpanId *)spanID
{
    [_gProfilersPerSpanID removeObjectForKey:spanID];
    [profiler->_spansInFlight removeObject:spanID];
    if (profiler->_spansInFlight.count == 0) {
        [profiler captureEnvelope];
        [profiler->_transactions removeAllObjects];
    } else {
        SENTRY_LOG_DEBUG(@"Profiler %@ is waiting for more spans to complete.", profiler);
    }
}

+ (void)timeoutAbort
{
    std::lock_guard<std::mutex> l(_gProfilerLock);

    if (_gCurrentProfiler == nil) {
        SENTRY_LOG_DEBUG(@"No current profiler to stop.");
        return;
    }

    SENTRY_LOG_DEBUG(@"Stopping profiler %@ due to timeout.", _gCurrentProfiler);
    [self stopProfilerForReason:BuzzSentryProfilerTruncationReasonTimeout];
}

+ (void)backgroundAbort
{
    std::lock_guard<std::mutex> l(_gProfilerLock);

    if (_gCurrentProfiler == nil) {
        SENTRY_LOG_DEBUG(@"No current profiler to stop.");
        return;
    }

    SENTRY_LOG_DEBUG(@"Stopping profiler %@ due to timeout.", _gCurrentProfiler);
    [self stopProfilerForReason:BuzzSentryProfilerTruncationReasonAppMovedToBackground];
}

+ (void)stopProfilerForReason:(BuzzSentryProfilerTruncationReason)reason
{
    [_gCurrentProfiler->_timeoutTimer invalidate];
    [_gCurrentProfiler stop];
    _gCurrentProfiler->_truncationReason = reason;
#    if SENTRY_HAS_UIKIT
    _gCurrentProfiler->_frameInfo = BuzzSentryFramesTracker.sharedInstance.currentFrames;
    [BuzzSentryFramesTracker.sharedInstance resetProfilingTimestamps];
#    endif // SENTRY_HAS_UIKIT
    _gCurrentProfiler = nil;
}

- (void)start
{
// Disable profiling when running with TSAN because it produces a TSAN false
// positive, similar to the situation described here:
// https://github.com/envoyproxy/envoy/issues/2561
#    if defined(__has_feature)
#        if __has_feature(thread_sanitizer)
    SENTRY_LOG_DEBUG(@"Disabling profiling when running with TSAN");
    return;
#            pragma clang diagnostic push
#            pragma clang diagnostic ignored "-Wunreachable-code"
#        endif
#    endif
    @synchronized(self) {
#    pragma clang diagnostic pop
        if (_profiler != nullptr) {
            _profiler->stopSampling();
        }
        _profile = [NSMutableDictionary<NSString *, id> dictionary];
        const auto sampledProfile = [NSMutableDictionary<NSString *, id> dictionary];

        /*
         * Maintain an index of unique frames to avoid duplicating large amounts of data. Every
         * unique frame is stored in an array, and every time a stack trace is captured for a
         * sample, the stack is stored as an array of integers indexing into the array of frames.
         * Stacks are thusly also stored as unique elements in their own index, an array of arrays
         * of frame indices, and each sample references a stack by index, to deduplicate common
         * stacks between samples, such as when the same deep function call runs across multiple
         * samples.
         *
         * E.g. if we have the following samples in the following function call stacks:
         *
         *              v sample1    v sample2               v sample3    v sample4
         * |-foo--------|------------|-----|    |-abc--------|------------|-----|
         *    |-bar-----|------------|--|          |-def-----|------------|--|
         *      |-baz---|------------|-|             |-ghi---|------------|-|
         *
         * Then we'd wind up with the following structures:
         *
         * frames: [
         *   { function: foo, instruction_addr: ... },
         *   { function: bar, instruction_addr: ... },
         *   { function: baz, instruction_addr: ... },
         *   { function: abc, instruction_addr: ... },
         *   { function: def, instruction_addr: ... },
         *   { function: ghi, instruction_addr: ... }
         * ]
         * stacks: [ [0, 1, 2], [3, 4, 5] ]
         * samples: [
         *   { stack_id: 0, ... },
         *   { stack_id: 0, ... },
         *   { stack_id: 1, ... },
         *   { stack_id: 1, ... }
         * ]
         */
        const auto samples = [NSMutableArray<NSDictionary<NSString *, id> *> array];
        const auto stacks = [NSMutableArray<NSMutableArray<NSNumber *> *> array];
        const auto frames = [NSMutableArray<NSDictionary<NSString *, id> *> array];
        sampledProfile[@"samples"] = samples;
        sampledProfile[@"stacks"] = stacks;
        sampledProfile[@"frames"] = frames;

        const auto threadMetadata =
            [NSMutableDictionary<NSString *, NSMutableDictionary *> dictionary];
        const auto queueMetadata = [NSMutableDictionary<NSString *, NSDictionary *> dictionary];
        sampledProfile[@"thread_metadata"] = threadMetadata;
        sampledProfile[@"queue_metadata"] = queueMetadata;
        _profile[@"profile"] = sampledProfile;
        _startTimestamp = getAbsoluteTime();
        _startDate = [BuzzSentryCurrentDate date];

        SENTRY_LOG_DEBUG(@"Starting profiler %@ at system time %llu.", self, _startTimestamp);

        __weak const auto weakSelf = self;
        _profiler = std::make_shared<SamplingProfiler>(
            [weakSelf, threadMetadata, queueMetadata, samples, mainThreadID = _mainThreadID, frames,
                stacks](auto &backtrace) {
                const auto strongSelf = weakSelf;
                if (strongSelf == nil) {
                    return;
                }
                const auto threadID = [@(backtrace.threadMetadata.threadID) stringValue];
                NSString *queueAddress = nil;
                if (backtrace.queueMetadata.address != 0) {
                    queueAddress = sentry_formatHexAddress(@(backtrace.queueMetadata.address));
                }
                NSMutableDictionary<NSString *, id> *metadata = threadMetadata[threadID];
                if (metadata == nil) {
                    metadata = [NSMutableDictionary<NSString *, id> dictionary];
                    threadMetadata[threadID] = metadata;
                }
                if (!backtrace.threadMetadata.name.empty() && metadata[@"name"] == nil) {
                    metadata[@"name"] =
                        [NSString stringWithUTF8String:backtrace.threadMetadata.name.c_str()];
                }
                if (backtrace.threadMetadata.priority != -1 && metadata[@"priority"] == nil) {
                    metadata[@"priority"] = @(backtrace.threadMetadata.priority);
                }
                if (queueAddress != nil && queueMetadata[queueAddress] == nil
                    && backtrace.queueMetadata.label != nullptr) {
                    queueMetadata[queueAddress] = @{
                        @"label" :
                            [NSString stringWithUTF8String:backtrace.queueMetadata.label->c_str()]
                    };
                }
#    if defined(DEBUG)
                const auto symbols
                    = backtrace_symbols(reinterpret_cast<void *const *>(backtrace.addresses.data()),
                        static_cast<int>(backtrace.addresses.size()));
#    endif

                const auto stack = [NSMutableArray<NSNumber *> array];
                const auto frameIndexLookup =
                    [NSMutableDictionary<NSString *, NSNumber *> dictionary];
                for (std::vector<uintptr_t>::size_type i = 0; i < backtrace.addresses.size(); i++) {
                    const auto instructionAddress
                        = sentry_formatHexAddress(@(backtrace.addresses[i]));

                    const auto frameIndex = frameIndexLookup[instructionAddress];

                    if (frameIndex == nil) {
                        const auto frame = [NSMutableDictionary<NSString *, id> dictionary];
                        frame[@"instruction_addr"] = instructionAddress;
#    if defined(DEBUG)
                        frame[@"function"] = parseBacktraceSymbolsFunctionName(symbols[i]);
#    endif
                        [stack addObject:@(frames.count)];
                        [frames addObject:frame];
                        frameIndexLookup[instructionAddress] = @(stack.count);
                    } else {
                        [stack addObject:frameIndex];
                    }
                }

                const auto sample = [NSMutableDictionary<NSString *, id> dictionary];
                sample[@"elapsed_since_start_ns"] =
                    [@(getDurationNs(strongSelf->_startTimestamp, backtrace.absoluteTimestamp))
                        stringValue];
                sample[@"thread_id"] = threadID;
                if (queueAddress != nil) {
                    sample[@"queue_address"] = queueAddress;
                }

                const auto stackIndex = [stacks indexOfObject:stack];
                if (stackIndex != NSNotFound) {
                    sample[@"stack_id"] = @(stackIndex);
                } else {
                    sample[@"stack_id"] = @(stacks.count);
                    [stacks addObject:stack];
                }

                [samples addObject:sample];
            },
            kBuzzSentryProfilerFrequencyHz);
        _profiler->startSampling();
    }
}

- (void)addTransaction:(nonnull BuzzSentryTransaction *)transaction
{
    NSParameterAssert(transaction);
    if (transaction == nil) {
        SENTRY_LOG_WARN(@"Received nil transaction!");
        return;
    }

    SENTRY_LOG_DEBUG(@"Adding transaction %@ to list of profiled transactions for profiler %@.",
        transaction, self);
    if (_transactions == nil) {
        _transactions = [NSMutableArray<BuzzSentryTransaction *> array];
    }
    [_transactions addObject:transaction];
}

- (void)stop
{
    @synchronized(self) {
        if (_profiler == nullptr || !_profiler->isSampling()) {
            return;
        }

        _profiler->stopSampling();
        _endTimestamp = getAbsoluteTime();
        _endDate = [BuzzSentryCurrentDate date];
        SENTRY_LOG_DEBUG(@"Stopped profiler %@ at system time: %llu.", self, _endTimestamp);
    }
}

- (void)captureEnvelope
{
    NSMutableDictionary<NSString *, id> *profile = nil;
    @synchronized(self) {
        profile = [_profile mutableCopy];
    }
    profile[@"version"] = @"1";
    const auto debugImages = [NSMutableArray<NSDictionary<NSString *, id> *> new];
    const auto debugMeta = [_debugImageProvider getDebugImages];
    for (BuzzSentryDebugMeta *debugImage in debugMeta) {
        const auto debugImageDict = [NSMutableDictionary<NSString *, id> dictionary];
        debugImageDict[@"type"] = @"macho";
        debugImageDict[@"debug_id"] = debugImage.uuid;
        debugImageDict[@"code_file"] = debugImage.name;
        debugImageDict[@"image_addr"] = debugImage.imageAddress;
        debugImageDict[@"image_size"] = debugImage.imageSize;
        debugImageDict[@"image_vmaddr"] = debugImage.imageVmAddress;
        [debugImages addObject:debugImageDict];
    }
    if (debugImages.count > 0) {
        profile[@"debug_meta"] = @{ @"images" : debugImages };
    }

    profile[@"os"] = @{
        @"name" : sentry_getOSName(),
        @"version" : sentry_getOSVersion(),
        @"build_number" : sentry_getOSBuildNumber()
    };

    const auto isEmulated = sentry_isSimulatorBuild();
    profile[@"device"] = @{
        @"architecture" : sentry_getCPUArchitecture(),
        @"is_emulator" : @(isEmulated),
        @"locale" : NSLocale.currentLocale.localeIdentifier,
        @"manufacturer" : @"Apple",
        @"model" : isEmulated ? sentry_getSimulatorDeviceModel() : sentry_getDeviceModel()
    };

    const auto profileID = [[BuzzSentryId alloc] init];
    profile[@"profile_id"] = profileID.buzzSentryIdString;
    const auto profileDuration = getDurationNs(_startTimestamp, _endTimestamp);
    profile[@"duration_ns"] = [@(profileDuration) stringValue];
    profile[@"truncation_reason"] = profilerTruncationReasonName(_truncationReason);
    profile[@"platform"] = _transactions.firstObject.platform;
    profile[@"environment"] = _hub.scope.environmentString ?: _hub.getClient.options.environment ?: kSentryDefaultEnvironment;
    profile[@"timestamp"] = [[BuzzSentryCurrentDate date] sentry_toIso8601String];

    const auto bundle = NSBundle.mainBundle;
    profile[@"release"] =
        [NSString stringWithFormat:@"%@ (%@)",
                  [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey],
                  [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];

#    if SENTRY_HAS_UIKIT
    auto relativeFrameTimestampsNs = [NSMutableArray array];
    [_frameInfo.frameTimestamps enumerateObjectsUsingBlock:^(
        NSDictionary<NSString *, NSNumber *> *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        const auto begin = (uint64_t)(obj[@"start_timestamp"].doubleValue * 1e9);
        if (begin < _startTimestamp) {
            return;
        }
        const auto end = (uint64_t)(obj[@"end_timestamp"].doubleValue * 1e9);
        const auto relativeEnd = getDurationNs(_startTimestamp, end);
        if (relativeEnd > profileDuration) {
            SENTRY_LOG_DEBUG(@"The last slow/frozen frame extended past the end of the profile, "
                             @"will not report it.");
            return;
        }
        [relativeFrameTimestampsNs addObject:@{
            @"start_timestamp_relative_ns" : @(getDurationNs(_startTimestamp, begin)),
            @"end_timestamp_relative_ns" : @(relativeEnd),
        }];
    }];
    profile[@"adverse_frame_render_timestamps"] = relativeFrameTimestampsNs;

    relativeFrameTimestampsNs = [NSMutableArray array];
    [_frameInfo.frameRateTimestamps enumerateObjectsUsingBlock:^(
        NSDictionary<NSString *, NSNumber *> *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        const auto timestamp = (uint64_t)(obj[@"timestamp"].doubleValue * 1e9);
        const auto refreshRate = obj[@"frame_rate"];
        uint64_t relativeTimestamp = 0;
        if (timestamp >= _startTimestamp) {
            relativeTimestamp = getDurationNs(_startTimestamp, timestamp);
        }
        [relativeFrameTimestampsNs addObject:@{
            @"start_timestamp_relative_ns" : @(relativeTimestamp),
            @"frame_rate" : refreshRate,
        }];
    }];
    profile[@"screen_frame_rates"] = relativeFrameTimestampsNs;
#    endif // SENTRY_HAS_UIKIT

    // populate info from all transactions that occurred while profiler was running
    auto transactionsInfo = [NSMutableArray array];
    for (BuzzSentryTransaction *transaction in _transactions) {
        const auto relativeStart =
            [NSString stringWithFormat:@"%llu",
                      [transaction.startTimestamp compare:_startDate] == NSOrderedAscending
                          ? 0
                          : (unsigned long long)(
                              [transaction.startTimestamp timeIntervalSinceDate:_startDate] * 1e9)];

        NSString *relativeEnd;
        if ([transaction.timestamp compare:_endDate] == NSOrderedDescending) {
            relativeEnd = [NSString stringWithFormat:@"%llu", profileDuration];
        } else {
            const auto profileStartToTransactionEnd_ns =
                [transaction.timestamp timeIntervalSinceDate:_startDate] * 1e9;
            if (profileStartToTransactionEnd_ns < 0) {
                SENTRY_LOG_DEBUG(@"Transaction %@ ended before the profiler started, won't "
                                 @"associate it with this profile.",
                    transaction.trace.context.traceId.buzzSentryIdString);
                continue;
            } else {
                relativeEnd = [NSString
                    stringWithFormat:@"%llu", (unsigned long long)profileStartToTransactionEnd_ns];
            }
        }
        [transactionsInfo addObject:@{
            @"id" : transaction.eventId.buzzSentryIdString,
            @"trace_id" : transaction.trace.context.traceId.buzzSentryIdString,
            @"name" : transaction.transaction,
            @"relative_start_ns" : relativeStart,
            @"relative_end_ns" : relativeEnd,
            @"active_thread_id" : [transaction.trace.transactionContext sentry_threadInfo].threadId
        }];
    }

    if (transactionsInfo.count == 0) {
        SENTRY_LOG_DEBUG(@"No transactions to associate with this profile, will not upload.");
        return;
    }
    profile[@"transactions"] = transactionsInfo;

    NSError *error = nil;
    const auto JSONData = [BuzzSentrySerialization dataWithJSONObject:profile error:&error];
    if (JSONData == nil) {
        SENTRY_LOG_DEBUG(@"Failed to encode profile to JSON: %@", error);
        return;
    }

    const auto header = [[BuzzSentryEnvelopeItemHeader alloc] initWithType:BuzzSentryEnvelopeItemTypeProfile
                                                                length:JSONData.length];
    const auto item = [[BuzzSentryEnvelopeItem alloc] initWithHeader:header data:JSONData];
    const auto envelopeHeader = [[BuzzSentryEnvelopeHeader alloc] initWithId:profileID];
    const auto envelope = [[BuzzSentryEnvelope alloc] initWithHeader:envelopeHeader singleItem:item];
    [_hub captureEnvelope:envelope];
}

- (BOOL)isRunning
{
    if (_profiler == nullptr) {
        return NO;
    }
    return _profiler->isSampling();
}

@end

#endif
