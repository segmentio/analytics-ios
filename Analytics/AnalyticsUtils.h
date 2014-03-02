// AnalyticsUtils.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>

#define NSStringize_helper(x) #x
#define NSStringize(x) @NSStringize_helper(x)

NSURL *AnalyticsURLForFilename(NSString *filename);

// Async Utils
dispatch_queue_t dispatch_queue_create_specific(const char *label, dispatch_queue_attr_t attr);
BOOL dispatch_is_on_specific_queue(dispatch_queue_t queue);
void dispatch_specific(dispatch_queue_t queue, dispatch_block_t block, BOOL waitForCompletion);
void dispatch_specific_async(dispatch_queue_t queue, dispatch_block_t block);
void dispatch_specific_sync(dispatch_queue_t queue, dispatch_block_t block);

// Logging

void SetShowDebugLogs(BOOL showDebugLogs);
void SOLog(NSString *format, ...);

// JSON Utils

NSDictionary *CoerceDictionary(NSDictionary *dict);
