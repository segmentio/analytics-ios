//
//  SEGUtils.m
//
//

#import "SEGUtils.h"
#import "SEGAnalyticsConfiguration.h"
#import "SEGReachability.h"
#import "SEGAnalytics.h"
#import "SEGHTTPClient.h"

#include <sys/sysctl.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
@import CoreTelephony;
static CTTelephonyNetworkInfo *_telephonyNetworkInfo;
#endif

const NSString *segment_apiHost = @"segment_apihost";

@implementation SEGUtils

+ (void)saveAPIHost:(nonnull NSString *)apiHost
{
    if (!apiHost) {
        return;
    }
    if (![apiHost containsString:@"https://"]) {
        apiHost = [NSString stringWithFormat:@"https://%@", apiHost];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:apiHost forKey:[segment_apiHost copy]];
}

+ (nonnull NSString *)getAPIHost
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *result = [defaults stringForKey:[segment_apiHost copy]];
    if (!result) {
        result = kSegmentAPIBaseHost;
    }
    return result;
}

+ (nullable NSURL *)getAPIHostURL
{
    return [NSURL URLWithString:[SEGUtils getAPIHost]];
}

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

    NSDictionary *settingsDictionary = nil;
#if TARGET_OS_IPHONE
    settingsDictionary = mobileSpecifications(configuration, deviceToken);
#elif TARGET_OS_OSX
    settingsDictionary = desktopSpecifications(configuration, deviceToken);
#endif
    
    if (settingsDictionary != nil) {
        dict[@"device"] = settingsDictionary[@"device"];
        dict[@"os"] = settingsDictionary[@"os"];
        dict[@"screen"] = settingsDictionary[@"screen"];
    }

    return dict;
}

#if TARGET_OS_IPHONE
NSDictionary *mobileSpecifications(SEGAnalyticsConfiguration *configuration, NSString *deviceToken)
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    UIDevice *device = [UIDevice currentDevice];
    dict[@"device"] = ({
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict[@"manufacturer"] = @"Apple";
#if TARGET_OS_MACCATALYST
        dict[@"type"] = @"macos";
        dict[@"name"] = @"Macintosh";
#else
        dict[@"type"] = @"ios";
        dict[@"name"] = [device model];
#endif
        dict[@"model"] = getDeviceModel();
        dict[@"id"] = [[device identifierForVendor] UUIDString];
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
#endif

#if TARGET_OS_OSX
NSString *getMacUUID()
{
    char buf[512] = { 0 };
    int bufSize = sizeof(buf);
    io_registry_entry_t ioRegistryRoot = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/");
    CFStringRef uuidCf = (CFStringRef) IORegistryEntryCreateCFProperty(ioRegistryRoot, CFSTR(kIOPlatformUUIDKey), kCFAllocatorDefault, 0);
    IOObjectRelease(ioRegistryRoot);
    CFStringGetCString(uuidCf, buf, bufSize, kCFStringEncodingMacRoman);
    CFRelease(uuidCf);
    return [NSString stringWithUTF8String:buf];
}

NSDictionary *desktopSpecifications(SEGAnalyticsConfiguration *configuration, NSString *deviceToken)
{
    NSProcessInfo *deviceInfo = [NSProcessInfo processInfo];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"device"] = ({
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict[@"manufacturer"] = @"Apple";
        dict[@"type"] = @"macos";
        dict[@"model"] = getDeviceModel();
        dict[@"id"] = getMacUUID();
        dict[@"name"] = [deviceInfo hostName];
        
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
        @"name" : deviceInfo.operatingSystemVersionString,
        @"version" : [NSString stringWithFormat:@"%ld.%ld.%ld",
                      deviceInfo.operatingSystemVersion.majorVersion,
                      deviceInfo.operatingSystemVersion.minorVersion,
                      deviceInfo.operatingSystemVersion.patchVersion]
    };

    CGSize screenSize = [NSScreen mainScreen].frame.size;
    dict[@"screen"] = @{
        @"width" : @(screenSize.width),
        @"height" : @(screenSize.height)
    };

    return dict;
}

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

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
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


@interface SEGISO8601NanosecondDateFormatter: NSDateFormatter
@end

@implementation SEGISO8601NanosecondDateFormatter

- (id)init
{
    self = [super init];
    self.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS:'Z'";
    self.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    self.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    return self;
}

const NSInteger __SEG_NANO_MAX_LENGTH = 9;
- (NSString * _Nonnull)stringFromDate:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitSecond | NSCalendarUnitNanosecond fromDate:date];
    NSString *genericDateString = [super stringFromDate:date];
    
    NSMutableArray *stringComponents = [[genericDateString componentsSeparatedByString:@"."] mutableCopy];
    NSString *nanoSeconds = [NSString stringWithFormat:@"%li", (long)dateComponents.nanosecond];
    
    if (nanoSeconds.length > __SEG_NANO_MAX_LENGTH) {
        nanoSeconds = [nanoSeconds substringToIndex:__SEG_NANO_MAX_LENGTH];
    } else {
        nanoSeconds = [nanoSeconds stringByPaddingToLength:__SEG_NANO_MAX_LENGTH withString:@"0" startingAtIndex:0];
    }
    
    NSString *result = [NSString stringWithFormat:@"%@.%@Z", stringComponents[0], nanoSeconds];
    
    return result;
}

@end


NSString *GenerateUUIDString()
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    NSString *UUIDString = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return UUIDString;
}


// Date Utils
NSString *iso8601NanoFormattedString(NSDate *date)
{
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[SEGISO8601NanosecondDateFormatter alloc] init];
    });
    return [dateFormatter stringFromDate:date];
}

NSString *iso8601FormattedString(NSDate *date)
{
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'";
        dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    });
    return [dateFormatter stringFromDate:date];
}


/** trim the queue so that it contains only upto `max` number of elements. */
void trimQueue(NSMutableArray *queue, NSUInteger max)
{
    if (queue.count < max) {
        return;
    }

    // Previously we didn't cap the queue. Hence there are cases where
    // the queue may already be larger than 1000 events. Delete as many
    // events as required to trim the queue size.
    NSRange range = NSMakeRange(0, queue.count - max);
    [queue removeObjectsInRange:range];
}

// Async Utils
dispatch_queue_t
seg_dispatch_queue_create_specific(const char *label,
                                   dispatch_queue_attr_t attr)
{
    dispatch_queue_t queue = dispatch_queue_create(label, attr);
    dispatch_queue_set_specific(queue, (__bridge const void *)queue,
                                (__bridge void *)queue, NULL);
    return queue;
}

BOOL seg_dispatch_is_on_specific_queue(dispatch_queue_t queue)
{
    return dispatch_get_specific((__bridge const void *)queue) != NULL;
}

void seg_dispatch_specific(dispatch_queue_t queue, dispatch_block_t block,
                           BOOL waitForCompletion)
{
    dispatch_block_t autoreleasing_block = ^{
        @autoreleasepool
        {
            block();
        }
    };
    if (dispatch_get_specific((__bridge const void *)queue)) {
        autoreleasing_block();
    } else if (waitForCompletion) {
        dispatch_sync(queue, autoreleasing_block);
    } else {
        dispatch_async(queue, autoreleasing_block);
    }
}

void seg_dispatch_specific_async(dispatch_queue_t queue,
                                 dispatch_block_t block)
{
    seg_dispatch_specific(queue, block, NO);
}

void seg_dispatch_specific_sync(dispatch_queue_t queue,
                                dispatch_block_t block)
{
    seg_dispatch_specific(queue, block, YES);
}

NSDictionary *SEGCoerceDictionary(NSDictionary *dict)
{
    // make sure that a new dictionary exists even if the input is null
    dict = dict ?: @{};
    // assert that the proper types are in the dictionary
    dict = [dict serializableDeepCopy];
    return dict;
}

NSString *SEGEventNameForScreenTitle(NSString *title)
{
    return [[NSString alloc] initWithFormat:@"Viewed %@ Screen", title];
}

@implementation NSJSONSerialization(Serializable)
+ (BOOL)isOfSerializableType:(id)obj
{
    if ([obj conformsToProtocol:@protocol(SEGSerializable)])
        return YES;
    
    if ([obj isKindOfClass:[NSArray class]] ||
        [obj isKindOfClass:[NSDictionary class]] ||
        [obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSNull class]])
        return YES;
    return NO;
}
@end


@implementation NSDictionary(SerializableDeepCopy)

- (id)serializableDeepCopy:(BOOL)mutable
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:self.count];
    NSArray *keys = [self allKeys];
    for (id key in keys) {
        id aValue = [self objectForKey:key];
        id theCopy = nil;
        
        if (![NSJSONSerialization isOfSerializableType:aValue]) {
            NSString *className = NSStringFromClass([aValue class]);
#ifdef DEBUG
            NSAssert(FALSE, @"key `%@` is a %@ and can't be serialized for delivery.", key, className);
#else
            SEGLog(@"key `%@` is a %@ and can't be serializaed for delivery.", key, className);
            // simply leave it out since we can't encode it anyway.
            continue;
#endif
        }
        
        if ([aValue conformsToProtocol:@protocol(SEGSerializableDeepCopy)]) {
            theCopy = [aValue serializableDeepCopy:mutable];
        } else if ([aValue conformsToProtocol:@protocol(SEGSerializable)]) {
            theCopy = [aValue serializeToAppropriateType];
        } else if ([aValue conformsToProtocol:@protocol(NSCopying)]) {
            theCopy = [aValue copy];
        } else {
            theCopy = aValue;
        }
        
        [result setValue:theCopy forKey:key];
    }
    
    if (mutable) {
        return result;
    } else {
        return [result copy];
    }
}

- (NSDictionary *)serializableDeepCopy {
    return [self serializableDeepCopy:NO];
}

- (NSMutableDictionary *)serializableMutableDeepCopy {
    return [self serializableDeepCopy:YES];
}

@end


@implementation NSArray(SerializableDeepCopy)

-(id)serializableDeepCopy:(BOOL)mutable
{
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:self.count];
    
    for (id aValue in self) {
        id theCopy = nil;
        
        if (![NSJSONSerialization isOfSerializableType:aValue]) {
            NSString *className = NSStringFromClass([aValue class]);
#ifdef DEBUG
            NSAssert(FALSE, @"found a %@ which can't be serialized for delivery.", className);
#else
            SEGLog(@"found a %@ which can't be serializaed for delivery.", className);
            // simply leave it out since we can't encode it anyway.
            continue;
#endif
        }

        if ([aValue conformsToProtocol:@protocol(SEGSerializableDeepCopy)]) {
            theCopy = [aValue serializableDeepCopy:mutable];
        } else if ([aValue conformsToProtocol:@protocol(SEGSerializable)]) {
            theCopy = [aValue serializeToAppropriateType];
        } else if ([aValue conformsToProtocol:@protocol(NSCopying)]) {
            theCopy = [aValue copy];
        } else {
            theCopy = aValue;
        }
        [result addObject:theCopy];
    }
    
    if (mutable) {
        return result;
    } else {
        return [result copy];
    }
}


- (NSArray *)serializableDeepCopy {
    return [self serializableDeepCopy:NO];
}

- (NSMutableArray *)serializableMutableDeepCopy {
    return [self serializableDeepCopy:YES];
}

@end
