//
//  AnalyticsUtils.h
//  Analytics
//
//  Created by Tony Xiao on 8/17/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import <Foundation/Foundation.h>

// Logging

void SetShowDebugLogs(BOOL showDebugLogs);
void SOLog(NSString *format, ...);

// JSON Utils

NSDictionary *CoerceDictionary(NSDictionary *dict);
id CoerceJSONObject(id obj);
void AssertDictionaryTypes(NSDictionary *dict);