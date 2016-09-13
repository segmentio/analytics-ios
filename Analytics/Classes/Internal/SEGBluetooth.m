#import "SEGBluetooth.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBCentralManagerConstants.h>


@interface SEGBluetooth () <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *manager;
#if OS_OBJECT_HAVE_OBJC_SUPPORT == 1
@property (nonatomic, strong) dispatch_queue_t queue;
#else
@property (nonatomic, assign) dispatch_queue_t queue;
#endif
@end


@implementation SEGBluetooth

- (id)init
{
    if (self = [super init]) {
        _queue = dispatch_queue_create("io.segment.bluetooth.queue", NULL);
        _manager = [[CBCentralManager alloc] initWithDelegate:self
                                                        queue:_queue
                                                      options:@{ CBCentralManagerOptionShowPowerAlertKey : @NO }];
    }
    return self;
}

- (BOOL)hasKnownState
{
    return _manager && (_manager.state != CBCentralManagerStateUnknown);
}

- (BOOL)isEnabled
{
    return _manager.state == CBCentralManagerStatePoweredOn;
}

- (void)centralManagerDidUpdateState:(id)central {}
@end
