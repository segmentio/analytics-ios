//
//  ViewController.m
//  AnalyticsApp
//
//  Created by Ilya Volodarsky on 7/4/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "ViewController.h"

#import "Reachability.h"

#import "JSONKit.h"
#import "SBJson.h"
#import "CJSONDeserializer.h"

#import "Analytics/Analytics.h"


@interface ViewController ()

@end

@implementation ViewController


- (void)enableReachability
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
    
    Reachability* reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
    
    if(remoteHostStatus == NotReachable) {NSLog(@"no");}
    else if (remoteHostStatus == ReachableViaWiFi) {NSLog(@"wifi"); }
    else if (remoteHostStatus == ReachableViaWWAN) {NSLog(@"cell"); }
}

- (NSDictionary *)getMonsterDictionary
{
    NSString *myString = @"something";
    NSNumber *myNumber = [[NSNumber alloc] initWithInt:42];
    NSNumber *myBool = @YES;
    NSDate *myDate = [NSDate date];
    NSURL *myUrl = [NSURL URLWithString:@"tel://1234567890x101"];
    
    NSArray *myArray = @[myString, myNumber, myBool, myDate, myUrl];
    
    NSDictionary *nested = @{
                             // NSString
                             @"string_nested" : myString,
                             // NSNumber
                             @"integer_nested": myNumber,
                             // Boolean
                             @"boolean_nested": myBool,
                             // NSDate
                             @"date_nested": myDate,
                             // NSURL
                             @"url_nested": myUrl,
                             // NSNull
                             @"null_nested": [NSNull null],
                             // NSArray
                             @"array_nested": myArray
                             };
    
    NSDictionary *dict = @{
                           @"string" : myString,
                           @"integer": myNumber,
                           @"boolean": myBool,
                           @"date": myDate,
                           @"url": myUrl,
                           @"null": [NSNull null],
                           @"array": myArray,
                           @"nestedDict": nested
                           };
    
    [self assertDictionaryTypes:dict];
    
    return dict;
}

//
// Thanks to Mixpanel's iOS library for being the basis
// of this example.
//
// Mixpanel.m
// Mixpanel
//
// Copyright 2012 Mixpanel
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

- (id)coerceJSONObject:(id)obj
{
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
            [a addObject:[self coerceJSONObject:i]];
        }
        return [NSArray arrayWithArray:a];
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (id key in obj) {
            NSString *stringKey;
            if (![key isKindOfClass:[NSString class]]) {
                stringKey = [key description];
                NSLog(@"%@ warning: dictionary keys should be strings. got: %@. coercing to: %@", self, [key class], stringKey);
            } else {
                stringKey = [NSString stringWithString:key];
            }
            
            id v = [self coerceJSONObject:[obj objectForKey:key]];
            [d setObject:v forKey:stringKey];
        }
        return [NSDictionary dictionaryWithDictionary:d];
    }
    
    // check for NSDate
    if ([obj isKindOfClass:[NSDate class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        NSString *s = [formatter stringFromDate:obj];
        return s;
    }
    // and NSUrl
    else if ([obj isKindOfClass:[NSURL class]]) {
        return [obj absoluteString];
    }
    
    // default to sending the object's description
    NSString *desc = [obj description];
    NSLog(@"%@ warning: dictionary values should be valid json types. got: %@. coercing to: %@", self, [obj class], desc);
    return desc;
}

- (void)assertDictionaryTypes:(NSDictionary *)dict
{
    for (id key in dict) {
        NSAssert([key isKindOfClass: [NSString class]], @"%@ dictionary key must be NSString. got: %@ %@", self, [key class], key);
        
        id value = [dict objectForKey:key];
        
        NSAssert([value isKindOfClass:[NSString class]] ||
                 [value isKindOfClass:[NSNumber class]] ||
                 [value isKindOfClass:[NSNull class]] ||
                 [value isKindOfClass:[NSArray class]] ||
                 [value isKindOfClass:[NSDictionary class]] ||
                 [value isKindOfClass:[NSDate class]] ||
                 [value isKindOfClass:[NSURL class]],
                 @"%@ Dictionary values must be NSString, NSNumber, NSNull, NSArray, NSDictionary, NSDate or NSURL. got: %@ %@", self, [[dict objectForKey:key] class], value);
    }
}

- (void)doFunJSON
{
    NSDictionary *monster = [self getMonsterDictionary];
    
    NSDictionary *coerced = [self coerceJSONObject:monster];
    
    // json kit serialization
    NSString *jsonKitJson = [coerced JSONString];
    
    NSLog(@"JSONKit = %@", jsonKitJson);
    
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];
    NSString* sbJson = [writer stringWithObject:coerced];

    NSLog(@"SBJson = %@", sbJson);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self enableReachability];
    [self doFunJSON];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onTrackClick:(id)sender {
    
    [[Analytics sharedAnalytics] track:@"PhotoStream \\/ Select filter" properties:@{ @"Available Offline": @"Option"}];
    
    NSDictionary *monster = [self getMonsterDictionary];
    
    [[Analytics sharedAnalytics] track:@"Monster Attack" properties:monster];
    
    NSLog(@"Sent analytics events");
}

@end
