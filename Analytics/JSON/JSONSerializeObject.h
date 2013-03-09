//  JSONSerializeObject.h
//  Copyright 2013 Segment.io


#import <Foundation/Foundation.h>

@interface JSONSerializeObject : NSObject

+ (NSData *)serialize:(id)obj;
+ (id)makeSerializable:(id)obj;

@end
