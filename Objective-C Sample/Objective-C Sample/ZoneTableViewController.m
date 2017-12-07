//
//  ZoneTableViewController.m
//  Objective-C Sample
//
//  Created by Leon van Dyk on 2017/11/16.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import "ZoneTableViewController.h"

@import Adyo;

#define DEMO_NETWORK_ID 1
#define DEMO_ZONE_ID 13

typedef NS_ENUM(NSInteger, CreativeType) {
    CreativeTypeAll,
    CreativeTypeRichMedia,
    CreativeTypeImage,
};

@interface ZoneTableViewController () <AYZoneViewDelegate>

@property (strong, nonatomic) IBOutlet UISegmentedControl *typeSegmentedControl;
@property (strong, nonatomic) IBOutlet UIView *zoneContainerView;
@property (strong, nonatomic) IBOutlet UIView *zoneContainerView2;
@property (strong, nonatomic) IBOutlet AYZoneView *zoneView;
@property (strong, nonatomic) IBOutlet AYZoneView *zoneView2;
@property (strong, nonatomic) IBOutlet UIView *timerView;
@property (strong, nonatomic) IBOutlet UIView *timerView2;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *timerWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *timerWidthConstraint2;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *timerTrailingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *timerTrailingConstraint2;



@property (strong, nonatomic) AYPlacementRequestParams *params;
@property (strong, nonatomic) AYPlacementRequestParams *params2;

- (IBAction)typeChanged;

@end

@implementation ZoneTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup placement request params for our zone views
    _params = [[AYPlacementRequestParams alloc] initWithNetworkId:DEMO_NETWORK_ID zoneId:DEMO_ZONE_ID];
    _params2 = [[AYPlacementRequestParams alloc] initWithNetworkId:DEMO_NETWORK_ID zoneId:DEMO_ZONE_ID];
    
    // Set zone view delegates to receive events
    _zoneView.delegate = self;
    _zoneView2.delegate = self;
    
    // The demo zone in backend is dynamically sized (no fixed width or height), so lets send through our width and heights and it will pick best sized creative
    _zoneView.detectSize = YES;
    _zoneView2.detectSize = YES;
    
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
            
            // Cool little animation using autolayout to show refresh rate
            [UIView animateWithDuration:placement.refreshAfter animations:^{
                _timerWidthConstraint.active = NO;
                _timerTrailingConstraint.active = YES;
                [_zoneContainerView layoutIfNeeded];
            } completion:^(BOOL finished) {
                _timerTrailingConstraint.active = NO;
                _timerWidthConstraint.active = YES;
                [_zoneContainerView layoutIfNeeded];
            }];
            
        } else {
            NSLog(@"Received placement on Zone #1. Refresh is 0 thus this    ad will stay.");
        }
        
    } else {
        
        if (!found) {
            NSLog(@"No placement found on Zone #2.");
        } else if (placement.refreshAfter > 0) {
            NSLog(@"Received placement on Zone #2. Automatically requesting new one in %d seconds..", (int)placement.refreshAfter);
            
            // Cool little animation using autolayout to show refresh rate
            [UIView animateWithDuration:placement.refreshAfter animations:^{
                _timerWidthConstraint2.active = NO;
                _timerTrailingConstraint2.active = YES;
                [_zoneContainerView2 layoutIfNeeded];
            } completion:^(BOOL finished) {
                _timerTrailingConstraint2.active = NO;
                _timerWidthConstraint2.active = YES;
                [_zoneContainerView2 layoutIfNeeded];
            }];
            
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

#pragma mark - Private

- (IBAction)typeChanged {
    
    // All Adyo demo placements for these zones have keywords to distinguish creative types for demo purposes when using the creative type segmented control
    switch (_typeSegmentedControl.selectedSegmentIndex) {
        case CreativeTypeAll:
            _params.keywords = @[];
            _params2.keywords = @[];
            break;
            
        case CreativeTypeRichMedia:
            _params.keywords = @[@"creative-type-rich-media"];
            _params2.keywords = @[@"creative-type-rich-media"];
            break;
            
        case CreativeTypeImage:
            _params.keywords = @[@"creative-type-image"];
            _params2.keywords = @[@"creative-type-image"];
            break;
            
        default:
            break;
    }
}

@end
