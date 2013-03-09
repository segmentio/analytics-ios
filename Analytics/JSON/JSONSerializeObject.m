//  JSONSerializeObject.m
//  Copyright 2013 Segment.io

#import "CJSONDataSerializer.h"
#import "DateFormat8601.h"

#import "JSONSerializeObject.h"


@implementation JSONSerializeObject


+ (NSData *)serialize:(id)obj
{
    id jsonSerializableObject = [self makeSerializable:obj];

    CJSONDataSerializer *serializer = [CJSONDataSerializer serializer];
    NSError *error = nil;
    NSData *data = nil;
    @try {
        data = [serializer serializeObject:jsonSerializableObject error:&error];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ exception serializing api data to json: %@", self, exception);
    }
    if (error) {
        NSLog(@"%@ error serializing api data to json: %@", self, error);
    }
    return data;
}

+ (id)makeSerializable:(id)obj
{
    // already valid json!
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }

    // urls (to strings)
    if ([obj isKindOfClass:[NSURL class]]) {
        return [obj absoluteString];
    }

    // dates (to strings)
    if ([obj isKindOfClass:[NSDate class]]) {
        return [DateFormat8601 formatDate:obj];
    }

    // arrays (iterate and convert)
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id nestedObj in obj) {
            [array addObject:[self makeSerializable:nestedObj]];
        }
        return [NSArray arrayWithArray:array];
    }

    // dictionaries (iterate and convert)
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (id key in obj) {
            NSString *keyStr;
            if (![key isKindOfClass:[NSString class]]) {
                keyStr = [key description];
                NSLog(@"%@ WARNING object keys should be strings. got %@, instead forcing it to be %@", self, [key class], keyStr);
            } else {
                keyStr = [NSString stringWithString:key];
            }
            id value = [self makeSerializable:[obj objectForKey:key]];
            [dict setObject:value forKey:keyStr];
        }
        return [NSDictionary dictionaryWithDictionary:dict];
    }

    // fallback to the description
    NSString *str = [obj description];
    NSLog(@"%@ WARNING objects should be valid json types. got %@, instead forcing it to be %@", self, [obj class], str);
    return str;
}

@end