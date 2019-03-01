//
//  AYPlacement.h
//  Adyo
//
//  Created by Leon van Dyk on 2017/11/10.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AYPlacement : NSObject

@property (strong, nonatomic) NSString *impressionUrl;
@property (strong, nonatomic) NSString *clickUrl;
@property (strong, nonatomic) NSString *creativeType;
@property (strong, nonatomic) NSString *creativeUrl;
@property (strong, nonatomic) NSString *creativeHtml;
@property (assign, nonatomic) NSTimeInterval refreshAfter;
@property (strong, nonatomic) NSString *thirdPartyImpressionUrl;
@property (strong, nonatomic) NSString *target;
@property (strong, nonatomic) NSURL *tagDomainUrl;
@property (strong, nonatomic) NSDictionary *metadata;
@property (assign, nonatomic) CGFloat width;
@property (assign, nonatomic) CGFloat height;

- (void)recordImpression:(void (^)(void))success
                 failure:(void (^)(NSError *adyoError, NSError *thirdPartyError))failure;

@end
