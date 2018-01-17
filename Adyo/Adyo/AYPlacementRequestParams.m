//
//  AYPlacementRequestParams.m
//  Adyo
//
//  Created by Leon van Dyk on 2017/11/10.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import "AYPlacementRequestParams.h"

@implementation AYPlacementRequestParams

- (id)initWithNetworkId:(NSUInteger)networkId
                 zoneId:(NSUInteger)zoneId {
    
    self = [super init];
    
    if (self) {
        _networkId = networkId;
        _zoneId = zoneId;
    }
    
    return self;
}

- (id)initWithNetworkId:(NSUInteger)networkId
                 zoneId:(NSUInteger)zoneId
                 userId:(NSString *)userId {
    
    self = [super init];
    
    if (self) {
        _networkId = networkId;
        _zoneId = zoneId;
        _userId = userId;
    }
    
    return self;
}

- (id)initWithNetworkId:(NSUInteger)networkId
                 zoneId:(NSUInteger)zoneId
                 userId:(NSString *)userId
               keywords:(NSArray<NSString *> *)keywords {
    
    self = [super init];
    
    if (self) {
        _networkId = networkId;
        _zoneId = zoneId;
        _userId = userId;
        _keywords = keywords;
    }
    
    return self;
}

- (id)initWithNetworkId:(NSUInteger)networkId
                   zoneId:(NSUInteger)zoneId
                   userId:(NSString *)userId
                 keywords:(NSArray<NSString *> *)keywords
                    width:(NSUInteger)width
                   height:(NSUInteger)height {
    
    self = [super init];
    
    if (self) {
        _networkId = networkId;
        _zoneId = zoneId;
        _userId = userId;
        _keywords = keywords;
        _width = width;
        _height = height;
    }
    
    return self;
}

- (id)initWithNetworkId:(NSUInteger)networkId
                 zoneId:(NSUInteger)zoneId
                 userId:(NSString *)userId
               keywords:(NSArray<NSString *> *)keywords
                  width:(NSUInteger)width
                 height:(NSUInteger)height
                 custom:(NSDictionary *)custom {
    
    self = [super init];
    
    if (self) {
        _networkId = networkId;
        _zoneId = zoneId;
        _userId = userId;
        _keywords = keywords;
        _width = width;
        _height = height;
        _custom = custom;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"<AYPlacementRequestParams: networkId: %zd, zoneId: %zd, userId: %zd, keywords: %@, width: %zd, height: %zd, custom: %@>", _networkId, _zoneId, _userId, _keywords, _width, _height, _custom];
}

@end
