// AnalyticsUtils.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGAnalyticsUtils.h"
#import <AdSupport/ASIdentifierManager.h>

static BOOL kAnalyticsLoggerShowLogs = NO;

NSURL *SEGAnalyticsURLForFilename(NSString *filename)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *supportPath = [paths firstObject];
    if (![[NSFileManager defaultManager] fileExistsAtPath:supportPath
                                              isDirectory:NULL]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:supportPath
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
            SEGLog(@"error: %@", error.localizedDescription);
        }
    }
    return [[NSURL alloc] initFileURLWithPath:[supportPath stringByAppendingPathComponent:filename]];
}

// Date Utils
NSString *iso8601FormattedString(NSDate *date)
{
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    });
    return [dateFormatter stringFromDate:date];
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
    if (dispatch_get_specific((__bridge const void *)queue)) {
        block();
    } else if (waitForCompletion) {
        dispatch_sync(queue, block);
    } else {
        dispatch_async(queue, block);
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

// Logging

void SEGSetShowDebugLogs(BOOL showDebugLogs)
{
    kAnalyticsLoggerShowLogs = showDebugLogs;
}

void SEGLog(NSString *format, ...)
{
    if (!kAnalyticsLoggerShowLogs)
        return;

    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
}

// JSON Utils

static id SEGCoerceJSONObject(id obj)
{
    // if the object is a NSString, NSNumber or NSNull
    // then we're good
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }

    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id i in obj)
            [array addObject:SEGCoerceJSONObject(i)];
        return array;
    }

    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (NSString *key in obj) {
            if (![key isKindOfClass:[NSString class]])
                SEGLog(@"warning: dictionary keys should be strings. got: %@. coercing "
                       @"to: %@",
                       [key class], [key description]);
            dict[key.description] = SEGCoerceJSONObject(obj[key]);
        }
        return dict;
    }

    if ([obj isKindOfClass:[NSDate class]])
        return iso8601FormattedString(obj);

    if ([obj isKindOfClass:[NSURL class]])
        return [obj absoluteString];

    // default to sending the object's description
    SEGLog(@"warning: dictionary values should be valid json types. got: %@. "
           @"coercing to: %@",
           [obj class], [obj description]);
    return [obj description];
}

static void AssertDictionaryTypes(id dict)
{
    assert([dict isKindOfClass:[NSDictionary class]]);
    for (id key in dict) {
        assert([key isKindOfClass:[NSString class]]);
        id value = dict[key];

        assert([value isKindOfClass:[NSString class]] ||
               [value isKindOfClass:[NSNumber class]] ||
               [value isKindOfClass:[NSNull class]] ||
               [value isKindOfClass:[NSArray class]] ||
               [value isKindOfClass:[NSDictionary class]] ||
               [value isKindOfClass:[NSDate class]] ||
               [value isKindOfClass:[NSURL class]]);
    }
}

NSDictionary *SEGCoerceDictionary(NSDictionary *dict)
{
    // make sure that a new dictionary exists even if the input is null
    dict = dict ?: @{};
    // assert that the proper types are in the dictionary
    AssertDictionaryTypes(dict);
    // coerce urls, and dates to the proper format
    return SEGCoerceJSONObject(dict);
}

NSString *SEGIDFA()
{
    NSString *idForAdvertiser = nil;
    Class identifierManager = NSClassFromString(@"ASIdentifierManager");
    if (identifierManager) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager =
            ((id (*)(id, SEL))
                 [identifierManager methodForSelector:sharedManagerSelector])(
                identifierManager, sharedManagerSelector);
        SEL advertisingIdentifierSelector =
            NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid =
            ((NSUUID * (*)(id, SEL))
                 [sharedManager methodForSelector:advertisingIdentifierSelector])(
                sharedManager, advertisingIdentifierSelector);
        idForAdvertiser = [uuid UUIDString];
    }
    return idForAdvertiser;
}

NSString *SEGEventNameForScreenTitle(NSString *title)
{
    return [[NSString alloc] initWithFormat:@"Viewed %@ Screen", title];
}
