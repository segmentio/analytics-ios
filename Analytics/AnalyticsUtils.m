//
//  SOUtils.m
//  Analytics
//
//  Created by Tony Xiao on 8/17/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "AnalyticsUtils.h"

static BOOL kAnalyticsLoggerShowLogs = NO;

// Logging

void SetShowDebugLogs(BOOL showDebugLogs) {
    kAnalyticsLoggerShowLogs = showDebugLogs;
}

void SOLog(NSString *format, ...) {   
    if (kAnalyticsLoggerShowLogs) {
        va_list args;
        va_start(args, format);
        NSLogv(format, args);
        va_end(args);
    }
}

// JSON Utils


static id CoerceJSONObject(id obj) {
    // if the object is a NSString, NSNumber or NSNull
    // then we're good
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *a = [NSMutableArray array];
        for (id i in obj) {
            [a addObject:CoerceJSONObject(i)];
        }
        return [NSArray arrayWithArray:a];
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (id key in obj) {
            NSString *stringKey;
            if (![key isKindOfClass:[NSString class]]) {
                stringKey = [key description];
                NSLog(@"warning: dictionary keys should be strings. got: %@. coercing to: %@", [key class], stringKey);
            } else {
                stringKey = [NSString stringWithString:key];
            }
            
            id v = CoerceJSONObject([obj objectForKey:key]);
            [d setObject:v forKey:stringKey];
        }
        return [NSDictionary dictionaryWithDictionary:d];
    }
    
    // check for NSDate, NSDate description is already a valid ISO8061 string
    if ([obj isKindOfClass:[NSDate class]]) {
        return [obj description];
    }
    // and NSUrl
    else if ([obj isKindOfClass:[NSURL class]]) {
        return [obj absoluteString];
    }
    
    // default to sending the object's description
    NSString *desc = [obj description];
    NSLog(@"warning: dictionary values should be valid json types. got: %@. coercing to: %@", [obj class], desc);
    return desc;
}

static void AssertDictionaryTypes(NSDictionary *dict) {
    for (id key in dict) {
        assert([key isKindOfClass: [NSString class]]);
        id value = [dict objectForKey:key];
        
        assert([value isKindOfClass:[NSString class]] ||
               [value isKindOfClass:[NSNumber class]] ||
               [value isKindOfClass:[NSNull class]] ||
               [value isKindOfClass:[NSArray class]] ||
               [value isKindOfClass:[NSDictionary class]] ||
               [value isKindOfClass:[NSDate class]] ||
               [value isKindOfClass:[NSURL class]]);
    }
}

NSDictionary *CoerceDictionary(NSDictionary *dict) {
    // make sure that a new dictionary exists even if the input is null
    NSDictionary * ensured = [NSDictionary dictionaryWithDictionary:dict];
    
    // assert that the proper types are in the dictionary
    AssertDictionaryTypes(ensured);
    
    // coerce urls, and dates to the proper format
    return CoerceJSONObject(ensured);
}

