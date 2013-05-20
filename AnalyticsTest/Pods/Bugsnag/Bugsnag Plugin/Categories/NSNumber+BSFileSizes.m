//
//  NSNumber+BSFileSizes.m
//  Bugsnag Notifier
//
//  Created by Simon Maynard on 12/6/12.
//
//

#import "NSNumber+BSFileSizes.h"

@implementation NSNumber (BSFileSizes)
- (NSString *)fileSize {
    float fileSize = [self floatValue];
    if (fileSize<1023.0f)
        return([NSString stringWithFormat:@"%i bytes",[self intValue]]);
    fileSize = fileSize / 1024.0f;
    if ([self intValue]<1023.0f)
        return([NSString stringWithFormat:@"%1.1f KB",fileSize]);
    fileSize = fileSize / 1024.0f;
    if (fileSize<1023.0f)
        return([NSString stringWithFormat:@"%1.1f MB",fileSize]);
    fileSize = fileSize / 1024.0f;
    
    return([NSString stringWithFormat:@"%1.1f GB",fileSize]);
}
@end
