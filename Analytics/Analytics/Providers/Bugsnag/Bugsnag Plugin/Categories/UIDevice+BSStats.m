//
//  UIDevice+BSStats.m
//  Bugsnag Notifier
//
//  Created by Simon Maynard on 12/6/12.
//
//

#import <fcntl.h>
#import <unistd.h>
#import <mach/mach.h>
#import <sys/sysctl.h>

#import "NSNumber+BSFileSizes.h"
#import "UIDevice+BSStats.h"

@implementation UIDevice (BSStats)

+ (NSString*) platform {
    size_t size = 256;
	char *machineCString = malloc(size);
    sysctlbyname("hw.machine", machineCString, &size, NULL, 0);
    NSString *machine = [NSString stringWithCString:machineCString encoding:NSUTF8StringEncoding];
    free(machineCString);
    
    if ([machine isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([machine isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([machine isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([machine isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([machine isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([machine isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([machine isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([machine isEqualToString:@"iPhone5,2"])    return @"iPhone S (CDMA)";
    if ([machine isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([machine isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([machine isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([machine isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([machine isEqualToString:@"iPod5,1"])      return @"iPod 5";
    if ([machine isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([machine isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([machine isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([machine isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([machine isEqualToString:@"iPad2,4"])      return @"iPad 2";
    if ([machine isEqualToString:@"iPad3,1"])      return @"iPad-3G (WiFi)";
    if ([machine isEqualToString:@"iPad3,2"])      return @"iPad-3G (4G)";
    if ([machine isEqualToString:@"iPad3,3"])      return @"iPad-3G (4G)";
    if ([machine isEqualToString:@"i386"])         return @"Simulator";
    if ([machine isEqualToString:@"x86_64"])       return @"Simulator";
    
    return machine;
}

+ (NSString *) osVersion {
#if TARGET_IPHONE_SIMULATOR
	return [[UIDevice currentDevice] systemVersion];
#else
	return [[NSProcessInfo processInfo] operatingSystemVersionString];
#endif
}

+ (NSString *) arch {
#ifdef _ARM_ARCH_7
    NSString *arch = @"armv7";
#else
#ifdef _ARM_ARCH_6
    NSString *arch = @"armv6";
#else
#ifdef __i386__
    NSString *arch = @"i386";
#endif
#endif
#endif
    return arch;
}

+ (NSDictionary *) memoryStats {
    natural_t usedMem = 0;
    natural_t freeMem = 0;
    natural_t totalMem = 0;
    
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        usedMem = info.resident_size;
        totalMem = info.virtual_size;
        freeMem = totalMem - usedMem;
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [[NSNumber numberWithInt:freeMem] fileSize], @"Free",
                [[NSNumber numberWithInt:totalMem] fileSize], @"Total",
                [[NSNumber numberWithInt:usedMem] fileSize], @"Used", nil];
    } else {
        return nil;
    }
}

+ (NSNumber *)uptime {
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    time_t now;
    time_t uptime = -1;
    
    (void)time(&now);
    
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0)
    {
        uptime = now - boottime.tv_sec;
    }
    
    return [NSNumber numberWithInt:uptime];
}

@end
