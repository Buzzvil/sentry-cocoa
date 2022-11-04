import Sentry

class TestBuzzSentryPermissionsObserver: BuzzSentryPermissionsObserver {
    var internalPushPermissionStatus = BuzzSentryPermissionStatus.unknown
    var internalLocationPermissionStatus = BuzzSentryPermissionStatus.unknown
    var internalMediaLibraryPermissionStatus = BuzzSentryPermissionStatus.unknown
    var internalPhotoLibraryPermissionStatus = BuzzSentryPermissionStatus.unknown

    override func startObserving() {
        // noop
    }

    override var pushPermissionStatus: BuzzSentryPermissionStatus {
        get {
            return internalPushPermissionStatus
        }
        set {}
    }

    override var locationPermissionStatus: BuzzSentryPermissionStatus {
        get {
            return internalLocationPermissionStatus
        }
        set {}
    }

    override var photoLibraryPermissionStatus: BuzzSentryPermissionStatus {
        get {
            return internalPhotoLibraryPermissionStatus
        }
        set {}
    }
}
