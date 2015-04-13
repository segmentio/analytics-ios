// SEGLeanplumIntegration.h
// Created by Scott Snibbe

#import <Foundation/Foundation.h>
#import "SEGAnalyticsIntegration.h"

@interface SEGLeanplumIntegration : SEGAnalyticsIntegration

@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) BOOL valid;
@property(nonatomic, assign) BOOL initialized;
@property(nonatomic, copy) NSDictionary *settings;

@end
