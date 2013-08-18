//
//  SOUtils.h
//  Analytics
//
//  Created by Tony Xiao on 8/17/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import <Foundation/Foundation.h>

NSDictionary *CoerceDictionary(NSDictionary *dict);
id CoerceJSONObject(id obj);
void AssertDictionaryTypes(NSDictionary *dict);