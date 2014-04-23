//
//  SIOBluetooth.m
//  Analytics
//
//  Created by Travis Jeffery on 4/23/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SIOBluetooth.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface SIOBluetooth ()

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, assign) dispatch_queue_t queue;

@end

@implementation SIOBluetooth

- (id)init {
    if (self = [super init]) {
        if ([CBCentralManager instancesRespondToSelector:@selector(initWithDelegate:queue:options:)]) {
            _queue = dispatch_queue_create("io.segment.bluetooth.queue", NULL);
            _manager = [[CBCentralManager alloc] initWithDelegate:self queue:_queue options:@{ CBCentralManagerOptionShowPowerAlertKey: @NO }];
        }
    }
    return self;
}

- (BOOL)isStateKnown {
    return _manager && _manager.state != CBCentralManagerStateUnknown;
}

- (BOOL)isEnabled {
    return _manager.state == CBCentralManagerStatePoweredOn;
}

@end
