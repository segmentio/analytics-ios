// SettingsCache.m
// Copyright 2013 Segment.io

#import "SettingsCache.h"

// Update the settings every hour
#define ANALYTICS_SETTINGS_CACHE_UPDATE_INTERVAL 3600

@interface SettingsCache ()

@property(nonatomic, strong) NSString *secret;
@property(nonatomic, strong) SettingsCacheDelegate *delegate;
@property(nonatomic, strong) NSTimer *updateTimer;
@property(nonatomic, strong) NSURLConnection *connection;
@property(nonatomic, assign) NSInteger responseCode;
@property(nonatomic, strong) NSMutableData *responseData;

@end




@implementation SettingsCache {
    dispatch_queue_t _serialQueue;
}

#pragma mark - Initializiation

+ (instancetype)withSecret:(NSString *)secret
{
    return [[self alloc] initWithSecret:secret delegate:nil];
}

+ (instancetype)withSecret:(NSString *)secret delegate:(SettingsCacheDelegate *)delegate
{
    NSParameterAssert(secret.length > 0);
    return [[self alloc] initWithSecret:secret delegate:delegate];
}

- (id)initWithSecret:(NSString *)secret delegate:(SettingsCacheDelegate *)delegate
{
    if (self = [self init]) {
        // Initialize all the components of the cache.
        _secret = secret;
        _delegate = delegate;
        _updateTimer = [NSTimer scheduledTimerWithTimeInterval:ANALYTICS_SETTINGS_CACHE_UPDATE_INTERVAL
                                                        target:self
                                                      selector:@selector(update)
                                                      userInfo:nil
                                                       repeats:YES];
        _serialQueue = dispatch_queue_create("io.segment.analytics.settings", DISPATCH_QUEUE_SERIAL);
        
        // Check the cache for synchronous return of cache results.
        NSDictionary *settings = [self getSettings];
        if (settings) {
            NSLog(@"Found settings in cache, will refresh cache later.");
            if (self.delegate) {
                NSLog(@"Calling delegate's onSettingsUpdate with cached settings.");
                [self.delegate onSettingsUpdate:settings];
            }
        }
        // Refresh the cache immediately if it's empty.
        else {
            NSLog(@"No settings in cache, refreshing cache now.");
            [self update];
        }
    }
    return self;
}

#pragma mark - Settings

static NSString * const kSettingsCache = @"kAnalyticsSettingsCache";

- (void)setSettings:(NSDictionary *)settings
{
    // Save the settings to the user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:(NSDictionary *)settings forKey:kSettingsCache];

    // Callback with the resulting settings
    NSLog(@"%@ Callback on delegate %@", self, self.delegate);
    if (self.delegate) {
        [self.delegate onSettingsUpdate:settings];
    }
}

- (NSDictionary *)getSettings
{
    // Get the settings from the user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults dictionaryForKey:kSettingsCache];
}

- (void)update
{
    // Start a request for the settings if not already in progress.
    if (self.connection == nil) {
        self.connection = [self connectionForSettings];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.connection start];
        });
    }
}

- (void)clear
{
    // Clear the settings from the user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kSettingsCache];
}



#pragma mark - Connection delegate callbacks

- (NSURLConnection *)connectionForSettings
{
    NSString *urlString = [NSString stringWithFormat:@"http://api.segment.io/project/%@/settings", self.secret];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPMethod:@"GET"];
    
    NSLog(@"%@ Sending API settings request: %@", self, request);
    
    return [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    NSAssert([NSThread isMainThread], @"Should be on main since URL connection should have started on main");
    self.responseCode = [response statusCode];
    self.responseData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSAssert([NSThread isMainThread], @"Should be on main since URL connection should have started on main");
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    dispatch_async(_serialQueue, ^{

        // Log the response status
        if (self.responseCode != 200) {
            NSLog(@"%@ Settings API request had an error: %@", self, [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]);
        }
        else {
            // Try to interpret the data as an NSDictionary of NSDictionarys
            NSError* error;
            NSDictionary* settings = [NSJSONSerialization JSONObjectWithData:self.responseData options:nil error:&error];
            NSLog(@"%@ Settings API request succeeded 200 %@", self, settings);
            [self setSettings:settings];
        }


        // Clear the request data
        self.responseCode = 0;
        self.responseData = nil;
        self.connection = nil;
    });
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    dispatch_async(_serialQueue, ^{
        NSLog(@"%@ Network failed while getting settings from API: %@", self, error);

        self.responseCode = 0;
        self.responseData = nil;
        self.connection = nil;
    });
}



#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Analytics SettingsCache secret:%@>", self.secret];
}

@end
