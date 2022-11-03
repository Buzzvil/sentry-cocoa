//
//  Use this file to import your target's public headers that you would like to
//  expose to Swift.
//
#import "NSData+Sentry.h"
#import "NSData+SentryCompression.h"
#import "NSDate+SentryExtras.h"
#import "NSURLProtocolSwizzle.h"
#import "PrivateBuzzSentrySDKOnly.h"
#import "BuzzSentryANRTracker.h"
#import "BuzzSentryANRTrackingIntegration.h"
#import "BuzzSentryAppStartMeasurement.h"
#import "BuzzSentryAppStartTracker.h"
#import "BuzzSentryAppStartTrackingIntegration.h"
#import "SentryAppState.h"
#import "SentryAppStateManager.h"
#import "BuzzSentryAttachment.h"
#import "BuzzSentryAutoBreadcrumbTrackingIntegration+Test.h"
#import "BuzzSentryAutoBreadcrumbTrackingIntegration.h"
#import "BuzzSentryAutoSessionTrackingIntegration.h"
#import "BuzzSentryBaggage.h"
#import "BuzzSentryBreadcrumbTracker.h"
#import "SentryByteCountFormatter.h"
#import "SentryClassRegistrator.h"
#import "BuzzSentryClient+Private.h"
#import "BuzzSentryClient+TestInit.h"
#import "BuzzSentryClientReport.h"
#import "BuzzSentryConcurrentRateLimitsDictionary.h"
#import "BuzzSentryCoreDataSwizzling.h"
#import "BuzzSentryCoreDataTracker.h"
#import "BuzzSentryCoreDataTrackingIntegration.h"
#import "SentryCrashBinaryImageProvider.h"
#import "SentryCrashC.h"
#import "SentryCrashDebug.h"
#import "SentryCrashDefaultBinaryImageProvider.h"
#import "SentryCrashDefaultMachineContextWrapper.h"
#import "SentryCrashInstallationReporter.h"
#import "SentryCrashIntegration+TestInit.h"
#import "SentryCrashIntegration.h"
#import "SentryCrashJSONCodecObjC.h"
#import "SentryCrashMachineContext.h"
#import "SentryCrashMonitor.h"
#import "SentryCrashMonitorContext.h"
#import "SentryCrashMonitor_AppState.h"
#import "SentryCrashMonitor_System.h"
#import "SentryCrashReport.h"
#import "SentryCrashReportSink.h"
#import "SentryCrashReportStore.h"
#import "SentryCrashScopeObserver.h"
#import "SentryCrashStackEntryMapper.h"
#import "SentryCrashUUIDConversion.h"
#import "SentryCrashWrapper.h"
#import "SentryCurrentDate.h"
#import "BuzzSentryDataCategory.h"
#import "BuzzSentryDataCategoryMapper.h"
#import "SentryDateUtil.h"
#import "SentryDebugImageProvider+TestInit.h"
#import "SentryDebugImageProvider.h"
#import "BuzzSentryDebugMeta.h"
#import "SentryDefaultCurrentDateProvider.h"
#import "SentryDefaultObjCRuntimeWrapper.h"
#import "BuzzSentryDefaultRateLimits.h"
#import "SentryDependencyContainer.h"
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
#import "SentryFileContents.h"
#import "SentryFileIOTrackingIntegration.h"
#import "SentryFileManager+TestProperties.h"
#import "SentryFileManager.h"
#import "BuzzSentryFrame.h"
#import "BuzzSentryFrameRemover.h"
#import "BuzzSentryFramesTracker+TestInit.h"
#import "BuzzSentryFramesTracker.h"
#import "BuzzSentryFramesTrackingIntegration.h"
#import "SentryGlobalEventProcessor.h"
#import "BuzzSentryHttpDateParser.h"
#import "BuzzSentryHttpTransport.h"
#import "SentryHub+Private.h"
#import "SentryHub+TestInit.h"
#import "BuzzSentryId.h"
#import "SentryInAppLogic.h"
#import "SentryInitializeForGettingSubclassesNotCalled.h"
#import "SentryInstallation.h"
#import "SentryInternalNotificationNames.h"
#import "SentryLevelMapper.h"
#import "SentryLog+TestInit.h"
#import "SentryLog.h"
#import "SentryLogOutput.h"
#import "BuzzSentryMechanism.h"
#import "BuzzSentryMechanismMeta.h"
#import "BuzzSentryMeta.h"
#import "SentryMigrateSessionInit.h"
#import "SentryNSDataTracker.h"
#import "BuzzSentryNSError.h"
#import "SentryNSNotificationCenterWrapper.h"
#import "BuzzSentryNSURLRequest.h"
#import "BuzzSentryNSURLRequestBuilder.h"
#import "BuzzSentryNSURLSessionTaskSearch.h"
#import "BuzzSentryNetworkTracker.h"
#import "BuzzSentryNetworkTrackingIntegration.h"
#import "BuzzSentryNoOpSpan.h"
#import "SentryObjCRuntimeWrapper.h"
#import "BuzzSentryOptions+Private.h"
#import "BuzzSentryOutOfMemoryLogic.h"
#import "BuzzSentryOutOfMemoryTracker.h"
#import "BuzzSentryOutOfMemoryTrackingIntegration.h"
#import "BuzzSentryPerformanceTracker.h"
#import "BuzzSentryPerformanceTrackingIntegration.h"
#import "BuzzSentryPredicateDescriptor.h"
#import "SentryProfiler+Test.h"
#import "BuzzSentryQueueableRequestManager.h"
#import "BuzzSentryRandom.h"
#import "BuzzSentryRateLimitParser.h"
#import "BuzzSentryRateLimits.h"
#import "BuzzSentryReachability.h"
#import "BuzzSentryRetryAfterHeaderParser.h"
#import "BuzzSentrySDK+Private.h"
#import "SentrySDK+Tests.h"
#import "SentryScope+Private.h"
#import "SentryScopeObserver.h"
#import "SentryScopeSyncC.h"
#import "BuzzSentryScreenFrames.h"
#import "BuzzSentryScreenshot.h"
#import "BuzzSentryScreenshotIntegration.h"
#import "SentrySdkInfo.h"
#import "SentrySerialization.h"
#import "BuzzSentrySession+Private.h"
#import "BuzzSentrySessionTracker.h"
#import "BuzzSentrySpan.h"
#import "BuzzSentrySpanId.h"
#import "BuzzSentryStacktrace.h"
#import "BuzzSentryStacktraceBuilder.h"
#import "BuzzSentrySubClassFinder.h"
#import "SentrySwizzleWrapper.h"
#import "SentrySysctl.h"
#import "BuzzSentrySystemEventBreadcrumbs.h"
#import "SentryTestIntegration.h"
#import "SentryTestObjCRuntimeWrapper.h"
#import "SentryThread.h"
#import "SentryThreadInspector.h"
#import "SentryThreadWrapper.h"
#import "SentryTime.h"
#import "BuzzSentryTraceContext.h"
#import "BuzzSentryTracer+Test.h"
#import "BuzzSentryTracer.h"
#import "BuzzSentryTransaction.h"
#import "BuzzSentryTransactionContext+Private.h"
#import "BuzzSentryTransport.h"
#import "BuzzSentryTransportAdapter.h"
#import "BuzzSentryTransportFactory.h"
#import "BuzzSentryUIApplication.h"
#import "SentryUIDeviceWrapper.h"
#import "BuzzSentryUIViewControllerPerformanceTracker.h"
#import "BuzzSentryUIViewControllerSanitizer.h"
#import "BuzzSentryUIViewControllerSwizzling+Test.h"
#import "BuzzSentryUIViewControllerSwizzling.h"
#import "BuzzSentryUserFeedback.h"
#import "BuzzSentryViewHierarchy.h"
#import "BuzzSentryViewHierarchyIntegration.h"
#import "TestNSURLRequestBuilder.h"
#import "TestSentryCrashWrapper.h"
#import "TestBuzzSentrySpan.h"
#import "TestUrlSession.h"
#import "UIView+Sentry.h"
#import "UIViewController+Sentry.h"
#import "URLSessionTaskMock.h"

#if SENTRY_HAS_UIKIT
#    import "SentryUIEventTracker.h"
#    import "SentryUIEventTrackingIntegration.h"
#endif
