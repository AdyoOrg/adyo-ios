//
//  ZoneTableViewController.m
//  Objective-C Sample
//
//  Created by Leon van Dyk on 2017/11/16.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import "ZoneTableViewController.h"

@import Adyo;

#define DEMO_NETWORK_ID 13
#define DEMO_ZONE_ID_1 3
#define DEMO_ZONE_ID_2 4

@interface ZoneTableViewController () <AYZoneViewDelegate>

@property (strong, nonatomic) IBOutlet AYZoneView *zoneView;
@property (strong, nonatomic) IBOutlet AYZoneView *zoneView2;

@property (strong, nonatomic) AYPlacementRequestParams *params;
@property (strong, nonatomic) AYPlacementRequestParams *params2;

@end

@implementation ZoneTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup placement request params for our zone views
    _params = [[AYPlacementRequestParams alloc] initWithNetworkId:DEMO_NETWORK_ID zoneId:DEMO_ZONE_ID_1];
    _params2 = [[AYPlacementRequestParams alloc] initWithNetworkId:DEMO_NETWORK_ID zoneId:DEMO_ZONE_ID_2];
    
    // Set zone view delegates to receive events
    _zoneView.delegate = self;
    _zoneView2.delegate = self;
    
    // Request placements (ads)
    [_zoneView requestPlacement:_params];
    [_zoneView2 requestPlacement:_params2];
}

#pragma mark - AYZoneViewDelegate

- (void)zoneView:(AYZoneView *)zoneView didReceivePlacement:(BOOL)found placement:(AYPlacement *)placement {
    
    if (zoneView == _zoneView) {
        
        if (!found) {
            NSLog(@"No placement found on Zone #1.");
        } else if (placement.refreshAfter > 0) {
            NSLog(@"Received placement on Zone #1. Automatically requesting new one in %d seconds..", (int)placement.refreshAfter);
        } else {
            NSLog(@"Received placement on Zone #1. Refresh is 0 thus this    ad will stay.");
        }
        
    } else {
        
        if (!found) {
            NSLog(@"No placement found on Zone #2.");
        } else if (placement.refreshAfter > 0) {
            NSLog(@"Received placement on Zone #2. Automatically requesting new one in %d seconds..", (int)placement.refreshAfter);
        } else {
            NSLog(@"Received placement on Zone #2. Refresh is 0 thus this ad will stay.");
        }
    }
}

- (void)zoneView:(AYZoneView *)zoneView didFailToReceivePlacement:(NSError *)error {
   
    // Placement request failed (probably due to internet, lets request it again in 2 seconds
    if (zoneView == _zoneView) {
        NSLog(@"Zone #1 placement request failed! Lets try again in 2 seconds..");
        [zoneView performSelector:@selector(requestPlacement:) withObject:_params afterDelay:2];
    } else {
        NSLog(@"Zone #2 placement request failed! Lets try again in 2 seconds..");
        [zoneView performSelector:@selector(requestPlacement:) withObject:_params2 afterDelay:2];
    }
}

@end
