//
//  Adyo.m
//  Adyo
//
//  Created by Leon van Dyk on 2017/11/10.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import "Adyo.h"
#import "UIDeviceHardware.h"

@import AdSupport;

#define BASE_URL @"https://engine.adyo.co.za/serve"
#define SDK_VERSION @"1.6.4"

@implementation Adyo

+ (void)requestPlacement:(AYPlacementRequestParams *)params
                 success:(void (^)(BOOL, AYPlacement *))success
                 failure:(void (^)(NSError *))failure {
    
    // Setup body for request
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    
    // Required
    data[@"network_id"] = [NSNumber numberWithUnsignedInteger:params.networkId];
    data[@"zone_id"] = [NSNumber numberWithUnsignedInteger:params.zoneId];
    
    // Optional User ID
    NSString *userId = params.userId;
    
    // If no user ID is specified, we still need a unique identifier for this user
    if (!userId) {
        
        // We check if user has advertising tracking enabled
        ASIdentifierManager *manager = [ASIdentifierManager sharedManager];
        
        if (manager.isAdvertisingTrackingEnabled) {
            userId = manager.advertisingIdentifier.UUIDString;
        }
        
        // If the user does not have tracking enabled, then we generate a unique ID per request. We respect the privacy of any end users that will see our ads.
        if (!userId || userId.length == 0) {
            userId = [NSUUID UUID].UUIDString;
        }
    }
    
    data[@"user_id"] = userId;
    
    // Optional Keywords
    NSArray *keywords = params.keywords;
    
    if (params.keywords == nil || [keywords isKindOfClass:[NSNull class]]) {
        keywords = @[]; // Empty array as API requires it
    }
    
    data[@"keywords"] = keywords;
    
    // Optional width and height
    if (params.width > 0 && params.height > 0) {
        data[@"width"] = [NSNumber numberWithUnsignedInteger:params.width];
        data[@"height"] = [NSNumber numberWithUnsignedInteger:params.height];
    }
    
    // Optional Custom Properties
    if (params.custom != nil && params.custom.count > 0) {
        data[@"custom"] = params.custom;
    }
    
    // Optional Creative Types
    if (params.creativeTypes != nil && [params.creativeTypes isKindOfClass:[NSArray class]] && params.creativeTypes.count > 0) {
        data[@"creative_types"] = params.creativeTypes;
    }
    
    NSData *postData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    NSString *model = [UIDeviceHardware platformString];
    NSString *platform = nil;
    
    if ([model containsString:@"iPad"]) {
        platform = @"iPad";
    } else if ([model containsString:@"iPhone"]) {
        platform = @"iPhone";
    } else if ([model containsString:@"iPod"]) {
        platform = @"iPod";
    } else {
        platform = @"Unknown";
    }
    
    // Now setup the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:BASE_URL]];
    
    [request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:SDK_VERSION forHTTPHeaderField:@"X-Adyo-SDK-Version"];
    [request setValue:platform forHTTPHeaderField:@"X-Adyo-Platform"];
    [request setValue:model forHTTPHeaderField:@"X-Adyo-Model"];
    [request setValue:@"iOS" forHTTPHeaderField:@"X-Adyo-OS"];
    [request setValue:[[UIDevice currentDevice] systemVersion] forHTTPHeaderField:@"X-Adyo-OS-Version"];
    [request setHTTPBody: postData];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error) {
        
            if (failure) {
                // Back to main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error);
                });
            }
            
            return;
        }
    
        // Decode JSON object
        NSError *decodeError;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&decodeError];
        
        if (decodeError) {
            
            if (failure) {
                
                // Back to main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(decodeError);
                });
            }
            
            return;
        }
        
        if (![result[@"found"] boolValue]) {
            
            if (success) {
                
                // Back to main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(NO, nil); // No placement was found
                });
            }
            
            return;
        }
        
        // Construct placement object and return it
        AYPlacement *placement = [[AYPlacement alloc] init];
        placement.impressionUrl = result[@"impression_url"];
        placement.clickUrl = result[@"click_url"];
        placement.creativeType = result[@"creative_type"];
        placement.refreshAfter = [result[@"refresh_after"] doubleValue];
        placement.target = result[@"app_target"];
        
        // Optional properties depending on creative type
        if ([result objectForKey:@"creative_url"] != nil && ![[result objectForKey:@"creative_url"] isKindOfClass:[NSNull class]]) {
            placement.creativeUrl = result[@"creative_url"];
        }
        
        if ([result objectForKey:@"creative_html"] != nil && ![[result objectForKey:@"creative_html"] isKindOfClass:[NSNull class]]) {
            placement.creativeHtml = result[@"creative_html"];
        }
        
        if ([result objectForKey:@"tag_domain"] != nil && ![[result objectForKey:@"tag_domain"] isKindOfClass:[NSNull class]]) {
            placement.tagDomainUrl = [NSURL URLWithString:result[@"tag_domain"]];
        }
        
        if ([result objectForKey:@"metadata"] != nil && ![[result objectForKey:@"metadata"] isKindOfClass:[NSNull class]]) {
            placement.metadata = result[@"metadata"];
        }
        
        if ([result objectForKey:@"width"] != nil && ![[result objectForKey:@"width"] isKindOfClass:[NSNull class]]) {
            placement.width = [result[@"width"] doubleValue];
        }
        
        if ([result objectForKey:@"height"] != nil && ![[result objectForKey:@"height"] isKindOfClass:[NSNull class]]) {
            placement.height = [result[@"height"] doubleValue];
        }
        
        if ([result objectForKey:@"matched_keywords"] != nil && ![[result objectForKey:@"matched_keywords"] isKindOfClass:[NSNull class]]) {
            placement.matchedKeywords = result[@"matched_keywords"];
        }
        
        if ([result objectForKey:@"third_party_impression_url"] != nil && ![[result objectForKey:@"third_party_impression_url"] isKindOfClass:[NSNull class]]) {
            placement.thirdPartyImpressionUrl = result[@"third_party_impression_url"];
        }
        
        if (success) {
            
            // Back to main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                success(YES, placement);
            });
        }
        
    }] resume];
}

@end
