import Foundation

@objc
public class TestBuzzSentryCrashBinaryImageProvider: NSObject, BuzzSentryCrashBinaryImageProvider {
    
    var binaryImage: [BuzzSentryCrashBinaryImage] = []
    public func getBinaryImage(_ index: Int) -> BuzzSentryCrashBinaryImage {
        binaryImage[Int(index)]
    }
    
    var imageCount = Int(0)
    public func getImageCount() -> Int {
        imageCount
    }
}
