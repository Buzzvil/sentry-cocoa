import XCTest

class BuzzSentryFrameRemoverTests: XCTestCase {
    
    private class Fixture {
        private func frame(withPackage package: String) -> Frame {
            let frame = Frame()
            frame.package = package
            return frame
        }
        
        var BuzzSentryFrame: Frame {
            return frame(withPackage: "/Users/sentry/private/var/containers/Bundle/Application/A722B503-2FA1-4C32-B5A7-E6FB47099C9D/iOS-Swift.app/Frameworks/Sentry.framework/Sentry")
        }
        
        var nonBuzzSentryFrame: Frame {
            return frame(withPackage: "/Users/sentry/private/var/containers/Bundle/Application/F42DD392-77D6-42B4-8092-D1AAE50C5B4B/iOS-Swift.app/iOS-Swift")
        }

        var BuzzSentryFrames: [Frame] {
            var frames: [Frame] = []
            (0...7).forEach { _ in frames.append(BuzzSentryFrame) }
            return frames
        }
        
        var nonBuzzSentryFrames: [Frame] {
            var frames: [Frame] = []
            (0...10).forEach { _ in frames.append(nonBuzzSentryFrame) }
            return frames
        }
    }
    
    private let fixture = Fixture()
    
    func testSdkFramesFirst_OnlyFirstBuzzSentryFramesRemoved() {
        let frames = fixture.BuzzSentryFrames +
            fixture.nonBuzzSentryFrames +
            [fixture.BuzzSentryFrame] +
            [fixture.nonBuzzSentryFrame]
        
        let expected = fixture.nonBuzzSentryFrames +
            [fixture.BuzzSentryFrame] +
            [fixture.nonBuzzSentryFrame]
        let actual = BuzzSentryFrameRemover.removeNonSdkFrames(frames)
        
        XCTAssertEqual(expected, actual)
    }
    
    func testNoSdkFramesFirst_NoFramesRemoved() {
        let frames = [fixture.nonBuzzSentryFrame] +
            [fixture.BuzzSentryFrame] +
            [fixture.nonBuzzSentryFrame]
        
        let actual = BuzzSentryFrameRemover.removeNonSdkFrames(frames)
                XCTAssertEqual(frames, actual)
    }
    
    func testNoSdkFrames_NoFramesRemoved() {
        let actual = BuzzSentryFrameRemover.removeNonSdkFrames(fixture.nonBuzzSentryFrames)
        XCTAssertEqual(fixture.nonBuzzSentryFrames, actual)
    }
    
    func testOnlySdkFrames_AllFramesRemoved() {
        let actual = BuzzSentryFrameRemover.removeNonSdkFrames(fixture.BuzzSentryFrames)
        XCTAssertEqual(fixture.BuzzSentryFrames, actual)
    }
}
