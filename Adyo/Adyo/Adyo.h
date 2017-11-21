//
//  Adyo.h
//  Adyo
//
//  Created by Leon van Dyk on 2017/11/10.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for Adyo.
FOUNDATION_EXPORT double AdyoVersionNumber;

//! Project version string for Adyo.
FOUNDATION_EXPORT const unsigned char AdyoVersionString[];

#import "Adyo/AYPlacementRequestParams.h"
#import "Adyo/AYPlacement.h"
#import "Adyo/AYZoneView.h"

// In this header, you should import all the public headers of your framework using statements like #import <Adyo/PublicHeader.h>

@interface Adyo : NSObject

+ (void)requestPlacement:(AYPlacementRequestParams *)params
                 success:(void (^)(BOOL found, AYPlacement *placement))success
                 failure:(void (^)(NSError *error))failure;

@end

