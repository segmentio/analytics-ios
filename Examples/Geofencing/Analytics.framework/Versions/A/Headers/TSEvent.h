#pragma once
#import <Foundation/Foundation.h>
#import "TSHelpers.h"

@interface TSEvent : NSObject {
@private
	NSTimeInterval firstFiredTime;
	NSString *uid;
	NSString *name;
	NSString *encodedName;
	BOOL isOneTimeOnly;
	BOOL isTransaction;
	NSString *productId;
	NSMutableDictionary *customFields;
	NSMutableString *postData;
}

@property(nonatomic, STRONG_OR_RETAIN, readonly) NSString *uid;
@property(nonatomic, STRONG_OR_RETAIN, readonly) NSString *name;
@property(nonatomic, STRONG_OR_RETAIN, readonly) NSString *encodedName;
@property(nonatomic, STRONG_OR_RETAIN, readonly) NSString *productId;
@property(nonatomic, STRONG_OR_RETAIN, readonly) NSMutableDictionary *customFields;
@property(nonatomic, STRONG_OR_RETAIN, readonly) NSString *postData;
@property (nonatomic, assign, readonly) BOOL isOneTimeOnly;
@property (nonatomic, assign, readonly) BOOL isTransaction;


+ (id)eventWithName:(NSString *)name oneTimeOnly:(BOOL)oneTimeOnly;
+ (id)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity;
+ (id)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity
	priceInCents:(int)priceInCents
	currency:(NSString *)currencyCode;

- (void)addValue:(NSObject *)obj forKey:(NSString *)key;


- (void)addIntegerValue:(int)value forKey:(NSString *)key				__attribute__((deprecated));
- (void)addUnsignedIntegerValue:(uint)value forKey:(NSString *)key 		__attribute__((deprecated));
- (void)addDoubleValue:(double)value forKey:(NSString *)key 			__attribute__((deprecated));
- (void)addFloatValue:(double)value forKey:(NSString *)key 				__attribute__((deprecated));
- (void)addBooleanValue:(BOOL)value forKey:(NSString *)key 				__attribute__((deprecated));


@end



