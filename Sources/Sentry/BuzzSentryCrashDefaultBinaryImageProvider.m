#import "BuzzSentryCrashDefaultBinaryImageProvider.h"
#import "BuzzSentryCrashBinaryImageProvider.h"
#import "SentryCrashDynamicLinker.h"
#import <Foundation/Foundation.h>

@implementation BuzzSentryCrashDefaultBinaryImageProvider

- (NSInteger)getImageCount
{
    return sentrycrashdl_imageCount();
}

- (SentryCrashBinaryImage)getBinaryImage:(NSInteger)index
{
    SentryCrashBinaryImage image = { 0 };
    sentrycrashdl_getBinaryImage((int)index, &image);
    return image;
}

@end
