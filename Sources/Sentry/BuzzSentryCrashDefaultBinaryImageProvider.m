#import "BuzzSentryCrashDefaultBinaryImageProvider.h"
#import "BuzzSentryCrashBinaryImageProvider.h"
#import "BuzzSentryCrashDynamicLinker.h"
#import <Foundation/Foundation.h>

@implementation BuzzSentryCrashDefaultBinaryImageProvider

- (NSInteger)getImageCount
{
    return sentrycrashdl_imageCount();
}

- (BuzzSentryCrashBinaryImage)getBinaryImage:(NSInteger)index
{
    BuzzSentryCrashBinaryImage image = { 0 };
    sentrycrashdl_getBinaryImage((int)index, &image);
    return image;
}

@end
