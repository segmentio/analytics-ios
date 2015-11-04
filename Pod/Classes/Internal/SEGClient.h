#import <Foundation/Foundation.h>

@interface SEGClient : NSObject

@property(nonatomic, readonly) NSString *writeKey;

-(instancetype) initWithWriteKey:(NSString *)writeKey;

-(NSDictionary *)settings;

@end
