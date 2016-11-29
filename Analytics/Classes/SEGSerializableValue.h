//
//  SEGSerializableValue.h
//  Analytics
//
//  Created by Tony Xiao on 11/29/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SEGSerializableValue <NSObject>
//@required
// NSString *, NSNumber *, NSNull *, or array / dict of them
//- (id)seg_jsonValue;
@end

// Includes both boolean and numbers
@interface NSNumber (SEGJSONValue) <SEGSerializableValue>
@end

@interface NSString (SEGJSONValue) <SEGSerializableValue>
@end

@interface NSNull (SEGJSONValue) <SEGSerializableValue>
@end

// If you use deeply nested data structures, Objective-C lightweight generics
// cannot help you statically check data type. It's your responsibility to
// ensure that nested values are JSON serializable
@interface NSDictionary (SEGJSONValue) <SEGSerializableValue>
@end

@interface NSArray (SEGJSONValue) <SEGSerializableValue>
@end

// We have helper methods to coerce the following types to JSON serializable types
// serializes to iso8601 format
@interface NSDate (SEGJSONValue) <SEGSerializableValue>
@end

// serializes to NSURL.absoluteURL
@interface NSURL (SEGJSONValue) <SEGSerializableValue>
@end

#define SERIALIZABLE_DICT NSDictionary<NSString *, id<SEGSerializableValue>> *

