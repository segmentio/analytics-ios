#import "SEGHTTPClient.h"
#import "NSData+SEGGZIP.h"
#import "SEGAnalyticsUtils.h"


@implementation SEGHTTPClient

+ (NSMutableURLRequest * (^)(NSURL *))defaultRequestFactory
{
    return ^(NSURL *url) {
        return [NSMutableURLRequest requestWithURL:url];
    };
}

- (instancetype)initWithRequestFactory:(SEGRequestFactory)requestFactory
{
    if (self = [self init]) {
        if (requestFactory == nil) {
            self.requestFactory = [SEGHTTPClient defaultRequestFactory];
        } else {
            self.requestFactory = requestFactory;
        }
    }
    return self;
}

- (NSString *)authorizationHeader:(NSString *)writeKey
{
    NSString *rawHeader = [writeKey stringByAppendingString:@":"];
    NSData *userPasswordData = [rawHeader dataUsingEncoding:NSUTF8StringEncoding];
    return [userPasswordData base64EncodedStringWithOptions:0];
}

- (NSURLSessionUploadTask *)upload:(NSDictionary *)batch forWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL retry))completionHandler
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPAdditionalHeaders = @{
        @"Accept-Encoding" : @"gzip",
        @"Content-Encoding" : @"gzip",
        @"Content-Type" : @"application/json",
        @"Authorization" : [@"Basic " stringByAppendingString:[self authorizationHeader:writeKey]],
    };
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSURL *url = [NSURL URLWithString:@"https://api.segment.io/v1/batch"];
    NSMutableURLRequest *request = self.requestFactory(url);
    [request setHTTPMethod:@"POST"];

    NSError *error = nil;
    NSException *exception = nil;
    NSData *payload = nil;
    @try {
        payload = [NSJSONSerialization dataWithJSONObject:batch options:0 error:&error];
    }
    @catch (NSException *exc) {
        exception = exc;
    }
    if (error || exception) {
        SEGLog(@"Error serializing JSON for batch upload %@", error);
        completionHandler(NO); // Don't retry this batch.
        return nil;
    }
    NSData *gzippedPayload = [payload seg_gzippedData];

    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:gzippedPayload completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error) {
            SEGLog(@"Error uploading request %@.", error);
            completionHandler(YES);
            return;
        }

        NSInteger code = ((NSHTTPURLResponse *)response).statusCode;
        if (code < 300) {
            // 2xx response codes.
            completionHandler(NO);
            return;
        }
        if (code < 400) {
            // 3xx response codes.
            SEGLog(@"Server responded with unexpected HTTP code %d.", code);
            completionHandler(YES);
            return;
        }
        if (code < 500) {
            // 4xx response codes.
            SEGLog(@"Server rejected payload with HTTP code %d.", code);
            completionHandler(NO);
            return;
        }

        // 5xx response codes.
        SEGLog(@"Server error with HTTP code %d.", code);
        completionHandler(YES);
    }];
    [task resume];
    return task;
}

- (NSURLSessionDataTask *)settingsForWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL success, NSDictionary *settings))completionHandler
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPAdditionalHeaders = @{
        @"Accept-Encoding" : @"gzip"
    };
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSString *rawURL = [NSString stringWithFormat:@"https://cdn.segment.com/v1/projects/%@/settings", writeKey];
    NSURL *url = [NSURL URLWithString:rawURL];
    NSMutableURLRequest *request = self.requestFactory(url);
    [request setHTTPMethod:@"GET"];

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error != nil) {
            SEGLog(@"Error fetching settings %@.", error);
            completionHandler(NO, nil);
            return;
        }

        NSInteger code = ((NSHTTPURLResponse *)response).statusCode;
        if (code > 300) {
            SEGLog(@"Server responded with unexpected HTTP code %d.", code);
            completionHandler(NO, nil);
            return;
        }

        NSError *jsonError = nil;
        id responseJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError != nil) {
            SEGLog(@"Error deserializing response body %@.", jsonError);
            completionHandler(NO, nil);
            return;
        }

        completionHandler(YES, responseJson);
    }];
    [task resume];
    return task;
}

- (NSURLSessionDataTask *)attributionWithWriteKey:(NSString *)writeKey forDevice:(NSDictionary *)context completionHandler:(void (^)(BOOL success, NSDictionary *properties))completionHandler;

{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPAdditionalHeaders = @{
        @"Accept-Encoding" : @"gzip",
        @"Content-Encoding" : @"gzip",
        @"Content-Type" : @"application/json",
        @"Authorization" : [@"Basic " stringByAppendingString:[self authorizationHeader:writeKey]],
    };
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSURL *url = [NSURL URLWithString:@"https://mobile-service.segment.com/v1/attribution"];
    NSMutableURLRequest *request = self.requestFactory(url);
    [request setHTTPMethod:@"POST"];

    NSError *error = nil;
    NSException *exception = nil;
    NSData *payload = nil;
    @try {
        payload = [NSJSONSerialization dataWithJSONObject:context options:0 error:&error];
    }
    @catch (NSException *exc) {
        exception = exc;
    }
    if (error || exception) {
        SEGLog(@"Error serializing context to JSON %@", error);
        completionHandler(NO, nil);
        return nil;
    }
    NSData *gzippedPayload = [payload seg_gzippedData];

    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:gzippedPayload completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
        if (error) {
            SEGLog(@"Error making request %@.", error);
            completionHandler(NO, nil);
            return;
        }

        NSInteger code = ((NSHTTPURLResponse *)response).statusCode;
        if (code > 300) {
            SEGLog(@"Server responded with unexpected HTTP code %d.", code);
            completionHandler(NO, nil);
            return;
        }

        NSError *jsonError = nil;
        id responseJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError != nil) {
            SEGLog(@"Error deserializing response body %@.", jsonError);
            completionHandler(NO, nil);
            return;
        }

        completionHandler(YES, responseJson);
    }];
    [task resume];
    return task;
}

@end
