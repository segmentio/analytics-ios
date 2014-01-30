#pragma once
#import "TSEvent.h"
#import "TSHit.h"
#import "TSResponse.h"

@protocol TSApi<NSObject>
- (void)fireEvent:(TSEvent *)event;
- (void)fireHit:(TSHit *)hit completion:(void(^)(TSResponse *))completion;
@end
