import Foundation
import BuzzSentry

func clearTestState() {
    BuzzSentrySDK.close()
    BuzzSentrySDK.setCurrentHub(nil)
    BuzzSentrySDK.crashedLastRunCalled = false
    BuzzSentrySDK.startInvocations = 0
    
    PrivateBuzzSentrySDKOnly.onAppStartMeasurementAvailable = nil
    PrivateBuzzSentrySDKOnly.appStartMeasurementHybridSDKMode = false
    BuzzSentrySDK.setAppStartMeasurement(nil)
    CurrentDate.setCurrentDateProvider(nil)
    BuzzSentryNetworkTracker.sharedInstance.disable()
    
    #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
    let framesTracker = BuzzSentryFramesTracker.sharedInstance()
    framesTracker.stop()
    framesTracker.resetFrames()
    
    setenv("ActivePrewarm", "0", 1)
    BuzzSentryAppStartTracker.load()
    #endif
    
    BuzzSentryDependencyContainer.reset()
    Dynamic(BuzzSentryGlobalEventProcessor.shared()).removeAllProcessors()
    BuzzSentrySwizzleWrapper.sharedInstance.removeAllCallbacks()
}
