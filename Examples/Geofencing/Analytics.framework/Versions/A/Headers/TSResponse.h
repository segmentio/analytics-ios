#pragma once
#import <Foundation/Foundation.h>

@interface TSResponse : NSObject {
@private
	int status;
	NSString *message;
	NSData *data;
}

@property(nonatomic, assign, readonly) int status;
@property(nonatomic, retain, readonly) NSString *message;
@property(nonatomic, retain, readonly) NSData *data;

- (id)initWithStatus:(int)status message:(NSString *)message data:(NSData *)data;

@end

