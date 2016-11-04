#import "SEGViewController.h"
#import "SEGAnalytics.h"


@interface SEGViewController ()

@end


@implementation SEGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    userActivity.webpageURL = [NSURL URLWithString:@"http://www.segment.com"];
    [[SEGAnalytics sharedAnalytics] continueUserActivity:userActivity];
    [[SEGAnalytics sharedAnalytics] track:@"test"];
    [[SEGAnalytics sharedAnalytics] flush];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
