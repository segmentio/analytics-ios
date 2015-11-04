#import "SEGClient.h"

@implementation SEGClient

-(instancetype)initWithWriteKey:(NSString *)writeKey
{
    if (self = [super init]) {
        _writeKey = writeKey;
    }
    return self;
}

-(NSDictionary *)settings
{
    NSString *url = [NSString stringWithFormat:@"https://cdn.segment.com/v1/projects/%@/settings", self.writeKey];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [urlRequest setHTTPMethod:@"GET"];
    
    NSHTTPURLResponse *response;
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    if (error != nil) {
        return nil;
    }
    
    if (response.statusCode == 200) {
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error != nil) {
            return nil;
        }
        return dictionary;
    }
    
    return nil;
}

@end
