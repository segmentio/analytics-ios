@import Foundation;
#import "SEGAnalytics.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSegmentAPIBaseHost;


NS_SWIFT_NAME(HTTPClient)
@interface SEGHTTPClient : NSObject

@property (nonatomic, strong) SEGRequestFactory requestFactory;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, NSURLSession *> *sessionsByWriteKey;
@property (nonatomic, readonly) NSURLSession *genericSession;
@property (nonatomic, weak)  id<NSURLSessionDelegate> httpSessionDelegate;

+ (SEGRequestFactory)defaultRequestFactory;
+ (NSString *)authorizationHeader:(NSString *)writeKey;

- (instancetype)initWithRequestFactory:(SEGRequestFactory _Nullable)requestFactory;

/**
 * Upload dictionary formatted as per https://segment.com/docs/sources/server/http/#batch.
 * This method will convert the dictionary to json, gzip it and upload the data.
 * It will respond with retry = YES if the batch should be reuploaded at a later time.
 * It will ask to retry for json errors and 3xx/5xx codes, and not retry for 2xx/4xx response codes.
 * NOTE: You need to re-dispatch within the completionHandler onto a desired queue to avoid threading issues.
 * Completion handlers are called on a dispatch queue internal to SEGHTTPClient. 
 */
- (nullable NSURLSessionUploadTask *)upload:(JSON_DICT)batch forWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL retry))completionHandler;

- (NSURLSessionDataTask *)settingsForWriteKey:(NSString *)writeKey completionHandler:(void (^)(BOOL success, JSON_DICT _Nullable settings))completionHandler;

@end

NS_ASSUME_NONNULL_END
