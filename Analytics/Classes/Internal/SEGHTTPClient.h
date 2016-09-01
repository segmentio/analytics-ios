#import <Foundation/Foundation.h>
#import "SEGAnalytics.h"


@interface SEGHTTPClient : NSObject

@property (nonatomic, strong) SEGRequestFactory requestFactory;

+ (SEGRequestFactory)defaultRequestFactory;

- (instancetype)initWithRequestFactory:(SEGRequestFactory)requestFactory;

/**
 * Upload dictionary formatted as per https://segment.com/docs/sources/server/http/#batch.
 * This method will convert the dictionary to json, gzip it and upload the data.
 * It will respond with retry = YES if the batch should be reuploaded at a later time.
 * It will ask to retry for json errors and 3xx/5xx codes, and not retry for 2xx/4xx response codes.
 */
- (NSURLSessionUploadTask *)upload:(NSDictionary *)batch forWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL retry))completionHandler;

- (NSURLSessionDataTask *)settingsForWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL success, NSDictionary *settings))completionHandler;

- (NSURLSessionDataTask *)attributionWithWriteKey:(NSString *)writeKey forDevice:(NSDictionary *)context completionHandler:(void (^)(BOOL success, NSDictionary *properties))completionHandler;

@end
