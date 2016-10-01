
#import <Analytics/SEGAnalytics.h>
#import "SEGViewController.h"


@interface SEGViewController ()

@end


@implementation SEGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)orderCompleted:(id)sender {
    [[SEGAnalytics sharedAnalytics] track:@"Middlewares Deployed"];
}

- (IBAction)flush:(id)sender {
    [[SEGAnalytics sharedAnalytics] flush];
}

@end
