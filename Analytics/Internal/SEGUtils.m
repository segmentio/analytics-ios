//
//  SEGUtils.m
//
//

#import "SEGUtils.h"
#import "SEGAnalyticsConfiguration.h"
#import "SEGReachability.h"
#import "SEGAnalytics.h"

#include <sys/sysctl.h>

#if TARGET_OS_IOS
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif

// BKS: This doesn't appear to be needed anymore.  Will investigate.
//NSString *const SEGADClientClass = @"ADClient";

@implementation SEGUtils

+ (NSData *_Nullable)dataFromPlist:(nonnull id)plist
{
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:plist
                                                              format:NSPropertyListXMLFormat_v1_0
                                                             options:0
                                                               error:&error];
    if (error) {
        SEGLog(@"Unable to serialize data from plist object", error, plist);
    }
    return data;
}

+ (id _Nullable)plistFromData:(NSData *_Nonnull)data
{
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithData:data
                                                         options:0
                                                          format:nil
                                                           error:&error];
    if (error) {
        SEGLog(@"Unable to parse plist from data %@", error);
    }
    return plist;
}


+(id)traverseJSON:(id)object andReplaceWithFilters:(NSDictionary<NSString*, NSString*>*)patterns
{
    if ([object isKindOfClass:NSDictionary.class]) {
        NSDictionary* dict = object;
        NSMutableDictionary* newDict = [NSMutableDictionary dictionaryWithCapacity:dict.count];
        
        for (NSString* key in dict.allKeys) {
            newDict[key] = [self traverseJSON:dict[key] andReplaceWithFilters:patterns];
        }
        
        return newDict;
    }
    
    if ([object isKindOfClass:NSArray.class]) {
        NSArray* array = object;
        NSMutableArray* newArray = [NSMutableArray arrayWithCapacity:array.count];
        
        for (int i = 0; i < array.count; i++) {
            newArray[i] = [self traverseJSON:array[i] andReplaceWithFilters:patterns];
        }
        
        return newArray;
    }

    if ([object isKindOfClass:NSString.class]) {
        NSError* error = nil;
        NSMutableString* str = [object mutableCopy];
        
        for (NSString* pattern in patterns) {
            NSRegularExpression* re = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                options:0
                                                                                  error:&error];
            
            if (error) {
                @throw error;
            }
            
            NSInteger matches = [re replaceMatchesInString:str
                                                   options:0
                                                     range:NSMakeRange(0, str.length)
                                              withTemplate:patterns[pattern]];
            
            if (matches > 0) {
                SEGLog(@"%@ Redacted value from action: %@", self, pattern);
            }
        }
        
        return str;
    }
    
    return object;
}

@end

BOOL isUnitTesting()
{
    static dispatch_once_t pred = 0;
    static BOOL _isUnitTesting = NO;
    dispatch_once(&pred, ^{
        NSDictionary *env = [NSProcessInfo processInfo].environment;
        _isUnitTesting = (env[@"XCTestConfigurationFilePath"] != nil);
    });
    return _isUnitTesting;
}

NSString *deviceTokenToString(NSData *deviceToken)
{
    if (!deviceToken) return nil;
    
    const unsigned char *buffer = (const unsigned char *)[deviceToken bytes];
    if (!buffer) {
        return nil;
    }
    NSMutableString *token = [NSMutableString stringWithCapacity:(deviceToken.length * 2)];
    for (NSUInteger i = 0; i < deviceToken.length; i++) {
        [token appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)buffer[i]]];
    }
    return token;
}

NSString *getDeviceModel()
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char result[size];
    sysctlbyname("hw.machine", result, &size, NULL, 0);
    NSString *results = [NSString stringWithCString:result encoding:NSUTF8StringEncoding];
    return results;
}

BOOL getAdTrackingEnabled(SEGAnalyticsConfiguration *configuration)
{
    BOOL result = NO;
    if ((configuration.adSupportBlock != nil) && (configuration.enableAdvertisingTracking)) {
        result = YES;
    }
    return result;
}

NSDictionary *getStaticContext(SEGAnalyticsConfiguration *configuration, NSString *deviceToken)
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    dict[@"library"] = @{
        @"name" : @"analytics-ios",
        @"version" : [SEGAnalytics version]
    };

    NSMutableDictionary *infoDictionary = [[[NSBundle mainBundle] infoDictionary] mutableCopy];
    [infoDictionary addEntriesFromDictionary:[[NSBundle mainBundle] localizedInfoDictionary]];
    if (infoDictionary.count) {
        dict[@"app"] = @{
            @"name" : infoDictionary[@"CFBundleDisplayName"] ?: @"",
            @"version" : infoDictionary[@"CFBundleShortVersionString"] ?: @"",
            @"build" : infoDictionary[@"CFBundleVersion"] ?: @"",
            @"namespace" : [[NSBundle mainBundle] bundleIdentifier] ?: @"",
        };
    }

    UIDevice *device = [UIDevice currentDevice];

    dict[@"device"] = ({
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict[@"manufacturer"] = @"Apple";
        dict[@"type"] = @"ios";
        dict[@"model"] = getDeviceModel();
        dict[@"id"] = [[device identifierForVendor] UUIDString];
        dict[@"name"] = [device model];
        if (getAdTrackingEnabled(configuration)) {
            NSString *idfa = configuration.adSupportBlock();
            // This isn't ideal.  We're doing this because we can't actually check if IDFA is enabled on
            // the customer device.  Apple docs and tests show that if it is disabled, one gets back all 0's.
            BOOL adTrackingEnabled = (![idfa isEqualToString:@"00000000-0000-0000-0000-000000000000"]);
            dict[@"adTrackingEnabled"] = @(adTrackingEnabled);

            if (adTrackingEnabled) {
                dict[@"advertisingId"] = idfa;
            }
        }
        if (deviceToken && deviceToken.length > 0) {
            dict[@"token"] = deviceToken;
        }
        dict;
    });

    dict[@"os"] = @{
        @"name" : device.systemName,
        @"version" : device.systemVersion
    };

    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    dict[@"screen"] = @{
        @"width" : @(screenSize.width),
        @"height" : @(screenSize.height)
    };

// BKS: This bit below doesn't seem to be effective anymore.  Will investigate later.
/*#if !(TARGET_IPHONE_SIMULATOR)
    Class adClient = NSClassFromString(SEGADClientClass);
    if (adClient) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id sharedClient = [adClient performSelector:NSSelectorFromString(@"sharedClient")];
#pragma clang diagnostic pop
        void (^completionHandler)(BOOL iad) = ^(BOOL iad) {
            if (iad) {
                dict[@"referrer"] = @{ @"type" : @"iad" };
            }
        };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [sharedClient performSelector:NSSelectorFromString(@"determineAppInstallationAttributionWithCompletionHandler:")
                           withObject:completionHandler];
#pragma clang diagnostic pop
    }
#endif*/

    return dict;
}

#if TARGET_OS_IOS
static CTTelephonyNetworkInfo *_telephonyNetworkInfo;
#endif

NSDictionary *getLiveContext(SEGReachability *reachability, NSDictionary *referrer, NSDictionary *traits)
{
    NSMutableDictionary *context = [[NSMutableDictionary alloc] init];
    context[@"locale"] = [NSString stringWithFormat:
                                       @"%@-%@",
                                       [NSLocale.currentLocale objectForKey:NSLocaleLanguageCode],
                                       [NSLocale.currentLocale objectForKey:NSLocaleCountryCode]];

    context[@"timezone"] = [[NSTimeZone localTimeZone] name];

    context[@"network"] = ({
        NSMutableDictionary *network = [[NSMutableDictionary alloc] init];

        if (reachability.isReachable) {
            network[@"wifi"] = @(reachability.isReachableViaWiFi);
            network[@"cellular"] = @(reachability.isReachableViaWWAN);
        }

#if TARGET_OS_IOS
        static dispatch_once_t networkInfoOnceToken;
        dispatch_once(&networkInfoOnceToken, ^{
            _telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
        });

        CTCarrier *carrier = [_telephonyNetworkInfo subscriberCellularProvider];
        if (carrier.carrierName.length)
            network[@"carrier"] = carrier.carrierName;
#endif

        network;
    });

    context[@"traits"] = [traits copy];

    if (referrer) {
        context[@"referrer"] = [referrer copy];
    }
    
    return [context copy];
}
