//
//  AYPlacement.h
//  Adyo
//
//  Created by Leon van Dyk on 2017/11/10.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AYPlacement : NSObject

@property (strong, nonatomic) NSString *impressionUrl;
@property (strong, nonatomic) NSString *clickUrl;
@property (strong, nonatomic) NSString *creativeType;
@property (strong, nonatomic) NSString *creativeUrl;
@property (assign, nonatomic) NSTimeInterval refreshAfter;
@property (assign, nonatomic) NSString *thirdPartyImpressionUrl;

- (void)recordImpression:(void (^)(void))success
                 failure:(void (^)(NSError *adyoError, NSError *thirdPartyError))failure;

@end
