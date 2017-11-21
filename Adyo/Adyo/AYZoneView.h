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
@property (nonatomic, weak) id<AYZoneViewDelegate> delegate;

- (void)requestPlacement:(AYPlacementRequestParams *)params;

@end
