//
//  BugsnagEvent.m
//  Bugsnag Notifier
//
//  Created by Simon Maynard on 12/6/12.
//
//

#import <execinfo.h>

#import "NSMutableDictionary+BSMerge.h"
#import "NSNumber+BSDuration.h"
#import "UIDevice+BSStats.h"
#import "UIViewController+BSVisibility.h"

#import "Reachability.h"
#import "BugsnagEvent.h"
#import "Bugsnag.h"
#import "BugsnagLogging.h"
#import "BugsnagPrivate.h"

@interface BugsnagEvent ()
+ (NSString *) generateErrorFilename;
+ (NSString *) errorPath;
@end

@implementation BugsnagEvent
+ (NSArray *) outstandingReports {
	NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.errorPath error:nil];
	NSMutableArray *outstandingReports = [NSMutableArray arrayWithCapacity:[directoryContents count]];
	for (NSString *file in directoryContents) {
		if ([[file pathExtension] isEqualToString:@"bugsnag"]) {
			NSString *crashPath = [self.errorPath stringByAppendingPathComponent:file];
			[outstandingReports addObject:crashPath];
		}
	}
	return outstandingReports;
}

+ (NSString*) errorPath {
    static NSString *errorPath = nil;
    if(errorPath) return errorPath;
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *filename = [folders count] == 0 ? NSTemporaryDirectory() : [folders objectAtIndex:0];
    errorPath = [filename stringByAppendingPathComponent:@"bugsnag"];
    return errorPath;
}

+ (NSString *) generateErrorFilename {
    return [[self.errorPath stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] stringByAppendingPathExtension:@"bugsnag"];
}

+ (void) writeEventToDisk:(NSDictionary*)event {
    //Ensure the bugsnag dir is there
    [[NSFileManager defaultManager] createDirectoryAtPath:[self errorPath] withIntermediateDirectories:YES attributes:nil error:nil];
    
    if(![event writeToFile:[self generateErrorFilename] atomically:YES]) {
        BugLog(@"BUGSNAG: Unable to write notice file!");
    }
}

+ (NSDictionary*) generateEventFromException:(NSException*)exception withMetaData:(NSDictionary*)passedMetaData {
    if([[exception callStackReturnAddresses] count] == 0) {
        @try {
            @throw exception;
        }
        @catch (NSException *exception) {}
    }
    NSUInteger frameCount = [[exception callStackReturnAddresses] count];
    void *frames[frameCount];
    for (NSInteger i = 0; i < frameCount; i++) {
        frames[i] = (void *)[[[exception callStackReturnAddresses] objectAtIndex:i] unsignedIntegerValue];
    }
    NSArray *stacktrace = [BugsnagEvent getCallStackFromFrames:frames andCount:frameCount startingAt:0];
    
    return [self generateEventFromErrorClass:exception.name
                                errorMessage:exception.reason
                                  stackTrace:stacktrace
                                    metaData:passedMetaData];
}

+ (NSDictionary*) generateEventFromErrorClass:(NSString*)errorClass
                                 errorMessage:(NSString*)errorMessage
                                   stackTrace:(NSArray*)stacktrace
                                     metaData:(NSDictionary*)passedMetaData {
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    
    @try {
        [event setObject:[Bugsnag instance].userId forKey:@"userId"];
        [event setObject:[Bugsnag instance].appVersion forKey:@"appVersion"];
        [event setObject:[UIDevice osVersion] forKey:@"osVersion"];
        [event setObject:[Bugsnag instance].releaseStage forKey:@"releaseStage"];
        
        NSString *context = [Bugsnag instance].context;
        if(context) {
            [event setObject:[Bugsnag instance].context forKey:@"context"];
        }
        
        NSMutableDictionary *exceptionDetails = [[NSMutableDictionary alloc] init];
        NSArray *exceptions = [[NSArray alloc] initWithObjects:exceptionDetails, nil];
        [event setObject:exceptions forKey:@"exceptions"];
        
        [exceptionDetails setObject:errorClass forKey:@"errorClass"];
        [exceptionDetails setObject:errorMessage forKey:@"message"];
        [exceptionDetails setObject:stacktrace forKey:@"stacktrace"];
        
        BugsnagMetaData *metaData = [[Bugsnag instance].metaData mutableCopy];
        [event setObject:metaData.dictionary forKey:@"metaData"];
        
        NSMutableDictionary *device = [metaData getTab:@"device"];
        
        [device setObject:[UIDevice platform] forKey:@"Device"];
        [device setObject:[UIDevice arch] forKey:@"Architecture"];
        [device setObject:[UIDevice osVersion] forKey:@"iOS Version"];
        [device setObject:[[UIDevice uptime] durationString] forKey:@"Time since boot"];
        
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        [reachability startNotifier];
        NetworkStatus status = [reachability currentReachabilityStatus];
        [reachability stopNotifier];
        
        if(status == NotReachable) {
            [device setObject:@"Not Reachable" forKey:@"Network"];
        } else if (status == ReachableViaWiFi) {
            [device setObject:@"Reachable via WiFi" forKey:@"Network"];
        } else if (status == ReachableViaWWAN) {
            [device setObject:@"Reachable via Mobile" forKey:@"Network"];
        }
        
        NSDictionary *memoryStats = [UIDevice memoryStats];
        if(memoryStats) {
            [device setObject:memoryStats forKey:@"Memory"];
        }
        
        NSMutableDictionary *application = [metaData getTab:@"application"];

        NSString *topViewControllerName = NSStringFromClass([[UIViewController getVisible] class]);
        if(topViewControllerName) {
            [application setObject:topViewControllerName forKey:@"Top View Controller"];
        }
        [application setObject:[Bugsnag instance].appVersion forKey:@"App Version"];
        [application setObject:[[NSBundle mainBundle] bundleIdentifier] forKey:@"Bundle Identifier"];
        
        NSMutableDictionary *session = [metaData getTab:@"session"];
        
        [session setObject:[[Bugsnag instance].sessionLength durationString] forKey:@"Session Length"];
        [session setObject:[NSNumber numberWithBool:[Bugsnag instance].inForeground] forKey:@"In Foreground"];
        
        if(passedMetaData) {
            [metaData mergeWith:passedMetaData];
        }
    }
    @catch (NSException *exception) {
        BugLog(@"Exception while creating bugsnag event: %@", exception);
    }
    
    return event;
}

+ (NSArray*) getCallStackFromFrames:(void*)frames andCount:(int)count startingAt:(int)start {
	char **strs = backtrace_symbols(frames, count);
    
    NSRegularExpression *stacktraceRegex = [NSRegularExpression regularExpressionWithPattern:@"[0-9]+\\s+(.*)\\s*(0x[0-9A-Fa-f]*)\\s*(.*)\\s*\\+"
                                                                                     options:NSRegularExpressionCaseInsensitive
                                                                                       error:nil];
    
	NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:count];
	for (NSInteger i = start; i < count; i++) {
		NSString *entry = [NSString stringWithUTF8String:strs[i]];
		NSMutableDictionary *lineDetails = [[NSMutableDictionary alloc] initWithCapacity:3];
        NSRange fullRange = NSMakeRange(0, [entry length]);
        
        NSTextCheckingResult* firstMatch = [stacktraceRegex firstMatchInString:entry options:0 range:fullRange];
        if (firstMatch) {
            NSString *packageName = [[entry substringWithRange:[firstMatch rangeAtIndex:1]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            NSString *method = [[entry substringWithRange:[firstMatch rangeAtIndex:3]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *file = [packageName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *lineNumber = [entry substringWithRange:[firstMatch rangeAtIndex:2]];
            
            if ( [packageName isEqualToString:[[NSProcessInfo processInfo] processName]] && ![method hasPrefix:@"+[Bugsnag "] && ![method hasPrefix:@"+[BugsnagEvent "]) {
                [lineDetails setObject:[NSNumber numberWithBool:YES] forKey:@"inProject"];
            }
            [lineDetails setObject:method forKey:@"method"];
            [lineDetails setObject:file forKey:@"file"];
            [lineDetails setObject:lineNumber forKey:@"lineNumber"];
        } else {
            [lineDetails setObject:@"UnknownMethod" forKey:@"method"];
            [lineDetails setObject:@"UnknownLineNumber" forKey:@"lineNumber"];
            [lineDetails setObject:@"UnknownFile" forKey:@"file"];
        }
        
        [backtrace addObject:lineDetails];
	}
	free(strs);
    return backtrace;
}
@end
