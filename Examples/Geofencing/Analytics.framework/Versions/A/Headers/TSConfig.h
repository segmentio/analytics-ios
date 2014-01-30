#pragma once
#import <Foundation/Foundation.h>
#import "TSHelpers.h"

@interface TSConfig : NSObject {
@private
	// Deprecated, hardware-id field
	NSString *hardware;

	// Optional hardware identifiers that can be provided by the caller
	NSString *odin1;
#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR	
	NSString *udid;
	NSString *idfa;
	NSString *secureUdid;
	NSString *openUdid;
#else
	NSString *serialNumber;
#endif
	
	// Set these to false if you do NOT want to collect this data
	BOOL collectWifiMac;

	// Set these if you want to override the names of the automatic events sent by the sdk
	NSString *installEventName;
	NSString *openEventName;

	// Unset these if you want to disable the sending of the automatic events
	BOOL fireAutomaticInstallEvent;
	BOOL fireAutomaticOpenEvent;
	BOOL fireAutomaticIAPEvents;
    
    // Unset this if you want to disable the collection of taste data
    BOOL collectTasteData;

	// These parameters will be automatically attached to all events fired by the sdk
	NSMutableDictionary *globalEventParams;
}

@property(nonatomic, STRONG_OR_RETAIN) NSString *hardware;
@property(nonatomic, STRONG_OR_RETAIN) NSString *odin1;
#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR	
@property(nonatomic, STRONG_OR_RETAIN) NSString *udid;
@property(nonatomic, STRONG_OR_RETAIN) NSString *idfa;
@property(nonatomic, STRONG_OR_RETAIN) NSString *secureUdid;
@property(nonatomic, STRONG_OR_RETAIN) NSString *openUdid;
#else
@property(nonatomic, STRONG_OR_RETAIN) NSString *serialNumber;
#endif

@property(nonatomic, assign) BOOL collectWifiMac;

@property(nonatomic, STRONG_OR_RETAIN) NSString *installEventName;
@property(nonatomic, STRONG_OR_RETAIN) NSString *openEventName;

@property(nonatomic, assign) BOOL fireAutomaticInstallEvent;
@property(nonatomic, assign) BOOL fireAutomaticOpenEvent;
@property(nonatomic, assign) BOOL fireAutomaticIAPEvents;

@property(nonatomic, assign) BOOL collectTasteData;

@property(nonatomic, STRONG_OR_RETAIN) NSMutableDictionary *globalEventParams;

+ (id)configWithDefaults;
- (id)init;

@end

