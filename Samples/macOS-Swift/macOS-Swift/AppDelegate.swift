import Cocoa
import Sentry

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        BuzzSentrySDK.start { options in
            options.dsn = "https://6cc9bae94def43cab8444a99e0031c28@o447951.ingest.sentry.io/5428557"
            options.debug = true
            options.sessionTrackingIntervalMillis = 5_000
            // Sampling 100% - In Production you probably want to adjust this
            options.tracesSampleRate = 1.0
            options.enableFileIOTracking = true
            if ProcessInfo.processInfo.arguments.contains("--io.sentry.profiling.enable") {
                options.profilesSampleRate = 1
            }
        }
        
        BuzzSentrySDK.configureScope { scope in
            if let path = Bundle.main.path(forResource: "Tongariro", ofType: "jpg") {
                scope.add(Attachment(path: path, filename: "Tongariro.jpg", contentType: "image/jpeg"))
            }
            
            if let data = "hello".data(using: .utf8) {
                scope.add(Attachment(data: data, filename: "log.txt"))
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}
