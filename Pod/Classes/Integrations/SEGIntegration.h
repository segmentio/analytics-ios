#import <Foundation/Foundation.h>

@protocol SEGIntegration

-(void) track:(NSString *)event properties:(NSDictionary *)properties;

@end
