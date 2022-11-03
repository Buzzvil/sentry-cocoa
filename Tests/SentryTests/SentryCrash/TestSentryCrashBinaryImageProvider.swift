import Foundation

@objc
public class TestBuzzSentryCrashBinaryImageProvider: NSObject, BuzzSentryCrashBinaryImageProvider {
    
    var binaryImage: [SentryCrashBinaryImage] = []
    public func getBinaryImage(_ index: Int) -> SentryCrashBinaryImage {
        binaryImage[Int(index)]
    }
    
    var imageCount = Int(0)
    public func getImageCount() -> Int {
        imageCount
    }
}
