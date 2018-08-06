//
//  AYZoneView.h
//  Adyo
//
//  Created by Leon van Dyk on 2017/11/10.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AYPlacement.h"
#import "AYPlacementRequestParams.h"

@class AYZoneView;

@protocol AYZoneViewDelegate <NSObject>

@optional

- (void)zoneView:(AYZoneView *)zoneView didReceivePlacement:(BOOL)found placement:(AYPlacement *)placement;
- (void)zoneView:(AYZoneView *)zoneView didFailToReceivePlacement:(NSError *)error;

@end

@interface AYZoneView : UIView

@property (assign, nonatomic) BOOL detectSize;

// Popup related
@property (weak, nonatomic) UIViewController *popupPresentingViewController;
@property (assign, nonatomic) NSUInteger popupInitialWidth;
@property (assign, nonatomic) NSUInteger popupInitialHeight;
@property (assign, nonatomic) BOOL popupScalesToContent;
@property (assign, nonatomic) BOOL popupShowLoader;
@property (strong, nonatomic) UIColor *popupOverlayColor;
@property (strong, nonatomic) UIColor *popupBackgroundColor;
@property (strong, nonatomic) UIColor *popupDoneButtonTintColor;
@property (strong, nonatomic) UIColor *popupBarTintColor;
@property (strong, nonatomic) NSString *popupDoneButtonText;
@property (assign, nonatomic) float popupCornerRadius;
@property (assign, nonatomic) UIModalPresentationStyle popupPresentationStyle;
@property (assign, nonatomic) UIModalTransitionStyle popupTransitionStyle;

@property (nonatomic, weak) id<AYZoneViewDelegate> delegate;
@property (readonly, assign, nonatomic) BOOL paused;

- (void)requestPlacement:(AYPlacementRequestParams *)params;
- (void)requestRandomPlacement:(NSArray<AYPlacementRequestParams *>*)params;
- (void)reset;
- (void)resume:(BOOL)immediately;
- (void)pause;
- (void)clear;

@end
