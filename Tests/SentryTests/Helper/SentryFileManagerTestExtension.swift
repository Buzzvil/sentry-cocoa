import Foundation
import XCTest

extension BuzzSentryFileManager {
    
    /**
     * Creates a file at the same path as BuzzSentryFileManager stores its files. When init on BuzzSentryFileManager is called the init is going to throw an error, because it can't create the internal folders.
     */
    static func prepareInitError() {
        deleteInternalPath()
        do {
            let data = "hello".data(using: .utf8)
            try data?.write(to: getInternalPath())
        } catch {
            XCTFail("Couldn't create file for init error of BuzzSentryFileManager.")
        }
    }
        
    /**
     * Deletes the file created with prepareInitError.
     */
    static func tearDownInitError() {
        deleteInternalPath()
    }
    
    private static func deleteInternalPath() {
        do {
            try FileManager.default.removeItem(at: getInternalPath())
        } catch {
            XCTFail("Couldn't delete internal path of BuzzSentryFileManager.")
        }
    }
    
    private static func getInternalPath() -> URL {
        let cachePath: String = FileManager.default
                .urls(for: .cachesDirectory, in: .userDomainMask)
                .map { dir in
                    dir.absoluteString
                }
                .first ?? ""

        let sentryPath = URL(fileURLWithPath: cachePath).appendingPathComponent("io.sentry")

        return sentryPath
    }
}
