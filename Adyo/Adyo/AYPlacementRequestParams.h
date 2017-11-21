//
//  AYPlacementRequestParams.h
//  Adyo
//
//  Created by Leon van Dyk on 2017/11/10.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AYPlacementRequestParams : NSObject

@property (assign, nonatomic) NSUInteger networkId;
@property (assign, nonatomic) NSUInteger zoneId;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSArray<NSString *> *keywords;
@property (assign, nonatomic) NSUInteger width;
@property (assign, nonatomic) NSUInteger height;

- (id)initWithNetworkId:(NSUInteger)networkId
                 zoneId:(NSUInteger)zoneId;

- (id)initWithNetworkId:(NSUInteger)networkId
                 zoneId:(NSUInteger)zoneId
                 userId:(NSString *)userId;

- (id)initWithNetworkId:(NSUInteger)networkId
                 zoneId:(NSUInteger)zoneId
                 userId:(NSString *)userId
               keywords:(NSArray<NSString *> *)keywords;

- (id)initWithNetworkId:(NSUInteger)networkId
                   zoneId:(NSUInteger)zoneId
                   userId:(NSString *)userId
                 keywords:(NSArray<NSString *> *)keywords
                    width:(NSUInteger)width
                   height:(NSUInteger)height;

@end
