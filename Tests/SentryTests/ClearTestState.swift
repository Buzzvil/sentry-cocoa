import Foundation
import Sentry

func clearTestState() {
    SentrySDK.close()
    SentrySDK.setCurrentHub(nil)
    SentrySDK.crashedLastRunCalled = false
    SentrySDK.startInvocations = 0
    
    PrivateBuzzSentrySDKOnly.onAppStartMeasurementAvailable = nil
    PrivateBuzzSentrySDKOnly.appStartMeasurementHybridSDKMode = false
    SentrySDK.setAppStartMeasurement(nil)
    CurrentDate.setCurrentDateProvider(nil)
    BuzzSentryNetworkTracker.sharedInstance.disable()
    
    #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
    let framesTracker = BuzzSentryFramesTracker.sharedInstance()
    framesTracker.stop()
    framesTracker.resetFrames()
    
    setenv("ActivePrewarm", "0", 1)
    BuzzSentryAppStartTracker.load()
    #endif
    
    SentryDependencyContainer.reset()
    Dynamic(SentryGlobalEventProcessor.shared()).removeAllProcessors()
    SentrySwizzleWrapper.sharedInstance.removeAllCallbacks()
}
