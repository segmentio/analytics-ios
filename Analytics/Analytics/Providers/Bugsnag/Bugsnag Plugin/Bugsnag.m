#import <execinfo.h>
#import <fcntl.h>
#import <unistd.h>
#import <sys/sysctl.h>

#import <Foundation/Foundation.h>
#import <mach/mach.h>

#import "UIViewController+BSVisibility.h"

#import "Bugsnag.h"
#import "BugsnagEvent.h"
#import "BugsnagNotifier.h"
#import "BugsnagLogging.h"
#import "BugsnagMetaData.h"
#import "BugsnagPrivate.h"

static Bugsnag *sharedBugsnagNotifier = nil;

int signals_count = 6;
int signals[] = {
	SIGABRT,
	SIGBUS,
	SIGFPE,
	SIGILL,
	SIGSEGV,
    EXC_BAD_ACCESS,
};

void remove_handlers(void);
void handle_signal(int);
void handle_exception(NSException *);

void remove_handlers() {
    for (NSUInteger i = 0; i < signals_count; i++) {
        int signalType = signals[i];
        signal(signalType, NULL);
    }
    NSSetUncaughtExceptionHandler(NULL);
}

// Handles a raised signal
void handle_signal(int signalReceived) {
    if (sharedBugsnagNotifier && [sharedBugsnagNotifier shouldAutoNotify]) {
        remove_handlers();
        
        // We limit to 128 lines of trace information for signals atm
        int count = 128;
		void *frames[count];
		count = backtrace(frames, count);
        
        NSDictionary *event = [BugsnagEvent generateEventFromErrorClass:[NSString stringWithCString:strsignal(signalReceived) encoding:NSUTF8StringEncoding]
                                                           errorMessage:@""
                                                             stackTrace:[BugsnagEvent getCallStackFromFrames:frames andCount:count startingAt:1]
                                                               metaData:nil];
        
        [BugsnagEvent writeEventToDisk:event];
    }
    //Propagate the signal back up to take the app down
    raise(signalReceived);
}

// Handles an uncaught exception
void handle_exception(NSException *exception) {
    if (sharedBugsnagNotifier && [sharedBugsnagNotifier shouldAutoNotify]) {
        remove_handlers();
        
        NSDictionary *event = [BugsnagEvent generateEventFromException:exception withMetaData:nil];
        
        [BugsnagEvent writeEventToDisk:event];
    }
}

@implementation Bugsnag

@synthesize releaseStage;
@synthesize apiKey;
@synthesize enableSSL;
@synthesize autoNotify;
@synthesize notifyReleaseStages;
@synthesize metaData;

// The start function. Entry point that should be called early on in application load
+ (void) startBugsnagWithApiKey:(NSString*)apiKey {
    NSLog(@"Starting the Bugsnag iOS Notifier!");
    [self instance].apiKey = apiKey;
    [BugsnagNotifier performSelectorInBackground:@selector(backgroundSendCachedReports) withObject:nil];
}

+ (Bugsnag *)instance {
    if(sharedBugsnagNotifier == nil) sharedBugsnagNotifier = [[Bugsnag alloc] init];
    return sharedBugsnagNotifier;
}

+ (void) notify:(NSException *)exception {
    [self notify:exception withData:nil];
}

+ (void) notify:(NSException *)exception withData:(NSDictionary*)metaData {
    if([self instance] && exception) {
        NSDictionary *event = [BugsnagEvent generateEventFromException:exception withMetaData:metaData];
        [BugsnagNotifier performSelectorInBackground:@selector(backgroundNotifyAndSend:) withObject:event];
    }
}

+ (void) setUserAttribute:(NSString*)attributeName withValue:(id)value {
    [self addAttribute:attributeName withValue:value toTabWithName:@"user"];
}

+ (void) clearUser {
    [self clearTabWithName:@"user"];
}

+ (void) addAttribute:(NSString*)attributeName withValue:(id)value toTabWithName:(NSString*)tabName {
    if(value) {
        [[[self instance].metaData getTab:tabName] setObject:value forKey:attributeName];
    } else {
        [[[self instance].metaData getTab:tabName] removeObjectForKey:attributeName];
    }
}

+ (void) clearTabWithName:(NSString*)tabName {
    [[self instance].metaData clearTab:tabName];
}

#pragma mark - Instance Methods
- (id) init {
    if ((self = [super init])) {
        _appVersion = nil;
        _userId = nil;
        _uuid = nil;
        self.metaData = [[BugsnagMetaData alloc] init];
        self.sessionStartDate = [NSDate date];
        self.enableSSL = YES;
        self.autoNotify = YES;
        self.inForeground = YES;
        self.notifyReleaseStages = [NSArray arrayWithObjects:@"production", @"development", nil];
        
        NSSetUncaughtExceptionHandler(&handle_exception);
        
        for (NSUInteger i = 0; i < signals_count; i++) {
            int signalType = signals[i];
            if (signal(signalType, handle_signal) != 0) {
                BugLog(@"Unable to register signal handler for %s", strsignal(signalType));
            }
        }
        
#ifdef DEBUG
        self.releaseStage = @"development";
#else
        self.releaseStage = @"production";
#endif
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (BOOL) shouldAutoNotify {
    return self.autoNotify && [self.notifyReleaseStages containsObject:self.releaseStage];
}

- (NSString*) appVersion {
    @synchronized(self){
        if(_appVersion) {
            return [_appVersion copy];
        } else {
            NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            if (bundleVersion != nil && versionString != nil && ![bundleVersion isEqualToString:versionString]) {
                self.appVersion = [NSString stringWithFormat:@"%@ (%@)", versionString, bundleVersion];
            } else if (bundleVersion != nil) {
                self.appVersion = bundleVersion;
            } else if(versionString != nil) {
                self.appVersion = versionString;
            }
            return [_appVersion copy];
        }
    }
}

- (void) setAppVersion:(NSString*)version {
    @synchronized(self) {
        _appVersion = [version copy];
    }
}

- (NSString*) userId {
    @synchronized(self) {
        if(_userId) {
            return [_userId copy];
        } else {
            return self.uuid;
        }
    }
}

- (void) setUserId:(NSString *)userId {
    @synchronized(self) {
        _userId = [userId copy];
    }
}

- (NSString*) context {
    @synchronized(self) {
        if(_context) return [_context copy];
        return NSStringFromClass([[UIViewController getVisible] class]);
    }
}

- (void) setContext:(NSString *)context {
    @synchronized(self) {
        _context = [context copy];
    }
}

- (NSString*) uuid {
    @synchronized(self) {
        // Return the already determined the UUID
        if(_uuid) return [_uuid copy];

        // Try to read UUID from NSUserDefaults
        _uuid = [[NSUserDefaults standardUserDefaults] stringForKey:@"bugsnag-user-id"];
        if(_uuid) {
            return [_uuid copy];
        }
        
        // Try to read UUID from disk - for backwards compat (used to write here)
        NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        if([folders count]) {
            NSString *filename = [[folders objectAtIndex:0] stringByAppendingPathComponent:@"bugsnag-user-id"];
            _uuid = [NSString stringWithContentsOfFile:filename encoding:NSStringEncodingConversionExternalRepresentation error:nil];
            if(_uuid) {
                // Write to NSUserdefaults so we get better caching
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setValue:_uuid forKey:@"bugsnag-user-id"];
                [defaults synchronize];
                return [_uuid copy];
            }
        }

        // Try to read Apple UUID for Vendor
        if([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
            _uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
            
            // We always check NSUserdefaults so we write the user id here for performance reasons
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setValue:_uuid forKey:@"bugsnag-user-id"];
            [defaults synchronize];
            return [_uuid copy];
        }

        // Generate a fresh UUID
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        _uuid = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
        CFRelease(uuid);

        // Try to save the UUID to the NSUserDefaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:_uuid forKey:@"bugsnag-user-id"];
        [defaults synchronize];
        return [_uuid copy];
    }
}

- (NSNumber *) sessionLength {
    return [NSNumber numberWithInt:-(int)[self.sessionStartDate timeIntervalSinceNow]];
}

- (void)applicationDidBecomeActive:(NSNotification *)notif {
    [BugsnagNotifier performSelectorInBackground:@selector(backgroundSendCachedReports) withObject:nil];
    self.inForeground = YES;
}

- (void)applicationDidEnterBackground:(NSNotification *)notif {
    self.inForeground = NO;
}
@end