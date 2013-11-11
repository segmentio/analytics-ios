// OmnitureProvider.m
// Copyright 2013 Segment.io

#import "ADMS_Measurement.h"
#import "OmnitureProvider.h"
#import "AnalyticsUtils.h"
#import "Analytics.h"

// http://microsite.omniture.com/t2/help/en_US/sc/appmeasurement/ios/index.html#Developer_Quick_Start

@implementation OmnitureProvider

#pragma mark - Initialization

+ (void)load {
    [Analytics registerProvider:self withIdentifier:@"Omniture"];
}

- (id)init {
    if (self = [super init]) {
        self.name = @"Omniture";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    // Require the Report Suite ID and Tracking Server.
    NSString *reportSuiteId = [self.settings objectForKey:@"reportSuiteId"];
    NSString *trackingServerUrl = [self.settings objectForKey:@"trackingServerUrl"];
    
    ADMS_Measurement *measurement = [ADMS_Measurement sharedInstance];
    [measurement configureMeasurementWithReportSuiteIDs:reportSuiteId trackingServer:trackingServerUrl];
    
    // Optionally turn on SSL.
    BOOL useSSL = [[self.settings objectForKey:@"useSSL"] boolValue];
    if (useSSL) {
        measurement.ssl = YES;
    }
    else {
        measurement.ssl = NO;
    }
    
    // Disable debug logging.
    measurement.debugLogging = YES;
    
    
    // Auto-tracking
    BOOL lifecycleAutoTracking = [[self.settings objectForKey:@"lifecycleAutoTracking"] boolValue];
    BOOL navigationAutoTracking = [[self.settings objectForKey:@"navigationAutoTracking"] boolValue];
    
    if (lifecycleAutoTracking && navigationAutoTracking) {
        // LifeCycle and navigation tracking enabled (iOS only)
        [measurement setAutoTrackingOptions:ADMS_AutoTrackOptionsLifecycle | ADMS_AutoTrackOptionsNavigation];
    }
    else if (lifecycleAutoTracking) {
        // LifeCycle auto tracking enabled (default)
        [measurement setAutoTrackingOptions:ADMS_AutoTrackOptionsLifecycle];
    }
    else if (navigationAutoTracking) {
        // Only Navigation auto tracking enabled (iOS only)
        [measurement setAutoTrackingOptions:ADMS_AutoTrackOptionsNavigation];
    }
    else {
        // Disable auto-tracking completely
        [measurement setAutoTrackingOptions:ADMS_AutoTrackOptionsNone];
    }
    
    // All done!
    SOLog(@"OmnitureProvider initialized.");
}


#pragma mark - Settings

- (void)validate
{
    // All that's required is the report suite and the tracking server.
    BOOL hasReportSuiteId = [self.settings objectForKey:@"reportSuiteId"] != nil;
    BOOL hasTrackingServerUrl = [self.settings objectForKey:@"trackingServerUrl"] != nil;
    self.valid = hasReportSuiteId && hasTrackingServerUrl;
}


#pragma mark - Analytics API


- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    // FEATURE: keep traits in a local store and merge them onto event/screen properties when they're sent?
    // set eVars and props?
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // Set props before tracking the event
    NSDictionary *propMap = [self.settings objectForKey:@"props"];
    for(id property in properties) {
        NSString *propertyMapped = [propMap objectForKey:property];
        if (propertyMapped != nil) {
            NSUInteger number = [self getNumberForSetting:propertyMapped];
            [[ADMS_Measurement sharedInstance] setProp:number toValue:properties[property]];
        }
        else {
            SOLog(@"The property %@ is not yet mapped to an Omniture propN in your integration page settings. Here are the existing props mappings: %@", property, propMap);
        }
    }
    
    // Set eVars before tracking the event.
    NSDictionary *eVarMap = [self.settings objectForKey:@"eVars"];
    for(id property in properties) {
        NSString *propertyMapped = [eVarMap objectForKey:property];
        if (propertyMapped != nil) {
            NSUInteger number = [self getNumberForSetting:propertyMapped];
            [[ADMS_Measurement sharedInstance] setEvar:number toValue:properties[property]];
        }
        else {
            SOLog(@"The property %@ is not yet mapped to an Omniture eVarN in your integration page settings. Here are the existing eVar mappings: %@", property, eVarMap);
        }
    }
    // eVars can also be the event, since they represent funnel steps.
    NSString *eventEVarMapped = [eVarMap objectForKey:event];
    if (eventEVarMapped != nil) {
        NSUInteger number = [self getNumberForSetting:eventEVarMapped];
        [[ADMS_Measurement sharedInstance] setEvar:number toValue:event];
    }
    else {
        SOLog(@"The event %@ is not yet mapped to an Omniture eVarN in your integration page settings. Here are the existing eVar mappings: %@", event, eVarMap);
    }
    
    // Finally map the event and send it if successful
    NSDictionary *eventMap = [self.settings objectForKey:@"events"];
    NSString *eventMapped = [eventMap objectForKey:event];
    if (eventMapped != nil) {
        [[ADMS_Measurement sharedInstance] trackEvents:eventMapped withContextData:properties];
    }
    else {
        SOLog(@"The event %@ is not yet mapped to Adobe (Omniture) eventN in your integration page settings. Here are the existing mappings: %@", event, eventMap);
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [[ADMS_Measurement sharedInstance] trackAppState:screenTitle withContextData:properties];
}

- (NSUInteger) getNumberForSetting:(NSString *)setting
{
    NSString *numberPart = [setting substringFromIndex:4];
    return (NSUInteger)[numberPart integerValue];
}

@end

