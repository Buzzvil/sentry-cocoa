//
//  Use this file to import your target's public headers that you would like to
//  expose to Swift.
//
#import "NSData+BuzzSentry.h"
#import "NSData+BuzzSentryCompression.h"
#import "NSDate+BuzzSentryExtras.h"
#import "NSURLProtocolSwizzle.h"
#import "PrivateBuzzSentrySDKOnly.h"
#import "BuzzSentryANRTracker.h"
#import "BuzzSentryANRTrackingIntegration.h"
#import "BuzzSentryAppStartMeasurement.h"
#import "BuzzSentryAppStartTracker.h"
#import "BuzzSentryAppStartTrackingIntegration.h"
#import "BuzzSentryAppState.h"
#import "BuzzSentryAppStateManager.h"
#import "BuzzSentryAttachment.h"
#import "BuzzSentryAutoBreadcrumbTrackingIntegration+Test.h"
#import "BuzzSentryAutoBreadcrumbTrackingIntegration.h"
#import "BuzzSentryAutoSessionTrackingIntegration.h"
#import "BuzzSentryBaggage.h"
#import "BuzzSentryBreadcrumbTracker.h"
#import "BuzzSentryByteCountFormatter.h"
#import "BuzzSentryClassRegistrator.h"
#import "BuzzSentryClient+Private.h"
#import "BuzzSentryClient+TestInit.h"
#import "BuzzSentryClientReport.h"
#import "BuzzSentryConcurrentRateLimitsDictionary.h"
#import "BuzzSentryCoreDataSwizzling.h"
#import "BuzzSentryCoreDataTracker.h"
#import "BuzzSentryCoreDataTrackingIntegration.h"
#import "BuzzSentryCrashBinaryImageProvider.h"
#import "BuzzSentryCrashC.h"
#import "BuzzSentryCrashDebug.h"
#import "BuzzSentryCrashDefaultBinaryImageProvider.h"
#import "BuzzSentryCrashDefaultMachineContextWrapper.h"
#import "BuzzSentryCrashInstallationReporter.h"
#import "BuzzSentryCrashIntegration+TestInit.h"
#import "BuzzSentryCrashIntegration.h"
#import "BuzzSentryCrashJSONCodecObjC.h"
#import "BuzzSentryCrashMachineContext.h"
#import "BuzzSentryCrashMonitor.h"
#import "BuzzSentryCrashMonitorContext.h"
#import "BuzzSentryCrashMonitor_AppState.h"
#import "BuzzSentryCrashMonitor_System.h"
#import "BuzzSentryCrashReport.h"
#import "BuzzSentryCrashReportSink.h"
#import "BuzzSentryCrashReportStore.h"
#import "BuzzSentryCrashScopeObserver.h"
#import "BuzzSentryCrashStackEntryMapper.h"
#import "BuzzSentryCrashUUIDConversion.h"
#import "BuzzSentryCrashWrapper.h"
#import "BuzzSentryCurrentDate.h"
#import "BuzzSentryDataCategory.h"
#import "BuzzSentryDataCategoryMapper.h"
#import "BuzzSentryDateUtil.h"
#import "BuzzSentryDebugImageProvider+TestInit.h"
#import "BuzzSentryDebugImageProvider.h"
#import "BuzzSentryDebugMeta.h"
#import "BuzzSentryDefaultCurrentDateProvider.h"
#import "BuzzSentryDefaultObjCRuntimeWrapper.h"
#import "BuzzSentryDefaultRateLimits.h"
#import "BuzzSentryDependencyContainer.h"
#import "BuzzSentryDiscardReason.h"
#import "BuzzSentryDiscardReasonMapper.h"
#import "BuzzSentryDiscardedEvent.h"
#import "BuzzSentryDispatchQueueWrapper.h"
#import "BuzzSentryDisplayLinkWrapper.h"
#import "BuzzSentryDsn.h"
#import "BuzzSentryEnvelope+Private.h"
#import "BuzzSentryEnvelopeItemType.h"
#import "BuzzSentryEnvelopeRateLimit.h"
#import "BuzzSentryEvent+Private.h"
#import "BuzzSentryFileContents.h"
#import "BuzzSentryFileIOTrackingIntegration.h"
#import "BuzzSentryFileManager+TestProperties.h"
#import "BuzzSentryFileManager.h"
#import "BuzzSentryFrame.h"
#import "BuzzSentryFrameRemover.h"
#import "BuzzSentryFramesTracker+TestInit.h"
#import "BuzzSentryFramesTracker.h"
#import "BuzzSentryFramesTrackingIntegration.h"
#import "BuzzSentryGlobalEventProcessor.h"
#import "BuzzSentryHttpDateParser.h"
#import "BuzzSentryHttpStatusCodeRange+Private.h"
#import "BuzzSentryHttpTransport.h"
#import "BuzzSentryHub+Private.h"
#import "BuzzSentryHub+TestInit.h"
#import "BuzzSentryId.h"
#import "BuzzSentryInAppLogic.h"
#import "SentryInitializeForGettingSubclassesNotCalled.h"
#import "BuzzSentryInstallation.h"
#import "BuzzSentryInternalNotificationNames.h"
#import "BuzzSentryLevelMapper.h"
#import "BuzzSentryLog+TestInit.h"
#import "BuzzSentryLog.h"
#import "BuzzSentryLogOutput.h"
#import "BuzzSentryMechanism.h"
#import "BuzzSentryMechanismMeta.h"
#import "BuzzSentryMeta.h"
#import "BuzzSentryMigrateSessionInit.h"
#import "BuzzSentryNSDataTracker.h"
#import "BuzzSentryNSError.h"
#import "BuzzSentryNSNotificationCenterWrapper.h"
#import "BuzzSentryNSURLRequest.h"
#import "BuzzSentryNSURLRequestBuilder.h"
#import "BuzzSentryNSURLSessionTaskSearch.h"
#import "BuzzSentryNetworkTracker.h"
#import "BuzzSentryNetworkTrackingIntegration.h"
#import "BuzzSentryNoOpSpan.h"
#import "BuzzSentryObjCRuntimeWrapper.h"
#import "BuzzSentryOptions+Private.h"
#import "BuzzSentryOutOfMemoryLogic.h"
#import "BuzzSentryOutOfMemoryTracker.h"
#import "BuzzSentryOutOfMemoryTrackingIntegration.h"
#import "BuzzSentryPerformanceTracker.h"
#import "BuzzSentryPerformanceTrackingIntegration.h"
#import "BuzzSentryPredicateDescriptor.h"
#import "BuzzSentryProfiler+Test.h"
#import "BuzzSentryQueueableRequestManager.h"
#import "BuzzSentryRandom.h"
#import "BuzzSentryRateLimitParser.h"
#import "BuzzSentryRateLimits.h"
#import "BuzzSentryReachability.h"
#import "BuzzSentryRetryAfterHeaderParser.h"
#import "BuzzSentrySDK+Private.h"
#import "BuzzSentrySDK+Tests.h"
#import "BuzzSentryScope+Private.h"
#import "BuzzSentryScopeObserver.h"
#import "BuzzSentryScopeSyncC.h"
#import "BuzzSentryScreenFrames.h"
#import "BuzzSentryScreenshot.h"
#import "BuzzSentryScreenshotIntegration.h"
#import "BuzzSentrySDKInfo.h"
#import "BuzzSentrySerialization.h"
#import "BuzzSentrySession+Private.h"
#import "BuzzSentrySessionTracker.h"
#import "BuzzSentrySpan.h"
#import "BuzzSentrySpanId.h"
#import "BuzzSentryStacktrace.h"
#import "BuzzSentryStacktraceBuilder.h"
#import "BuzzSentrySubClassFinder.h"
#import "BuzzSentrySwizzleWrapper.h"
#import "BuzzSentrySysctl.h"
#import "BuzzSentrySystemEventBreadcrumbs.h"
#import "SentryTestIntegration.h"
#import "SentryTestObjCRuntimeWrapper.h"
#import "BuzzSentryThread.h"
#import "BuzzSentryThreadInspector.h"
#import "BuzzSentryThreadWrapper.h"
#import "BuzzSentryTime.h"
#import "BuzzSentryTraceContext.h"
#import "BuzzSentryTracer+Test.h"
#import "BuzzSentryTracer.h"
#import "BuzzSentryTransaction.h"
#import "BuzzSentryTransactionContext+Private.h"
#import "BuzzSentryTransport.h"
#import "BuzzSentryTransportAdapter.h"
#import "BuzzSentryTransportFactory.h"
#import "BuzzSentryUIApplication.h"
#import "BuzzSentryUIDeviceWrapper.h"
#import "BuzzSentryUIViewControllerPerformanceTracker.h"
#import "BuzzSentryUIViewControllerSanitizer.h"
#import "BuzzSentryUIViewControllerSwizzling+Test.h"
#import "BuzzSentryUIViewControllerSwizzling.h"
#import "BuzzSentryUserFeedback.h"
#import "BuzzSentryViewHierarchy.h"
#import "BuzzSentryViewHierarchyIntegration.h"
#import "TestNSURLRequestBuilder.h"
#import "TestBuzzSentryCrashWrapper.h"
#import "TestBuzzSentrySpan.h"
#import "TestUrlSession.h"
#import "UIView+BuzzSentry.h"
#import "UIViewController+BuzzSentry.h"
#import "URLSessionTaskMock.h"

#if SENTRY_HAS_UIKIT
#    import "BuzzSentryUIEventTracker.h"
#    import "BuzzSentryUIEventTrackingIntegration.h"
#endif
