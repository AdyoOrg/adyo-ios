//
//  AYPlacement.m
//  Adyo
//
//  Created by Leon van Dyk on 2017/11/10.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import "AYPlacement.h"
#import "UIDeviceHardware.h"

@import UIKit;

@implementation AYPlacement

- (void)recordImpression:(void (^)(void))success
                 failure:(void (^)(NSError *, NSError *))failure {
    
    // We need to get the user agent and other attributes for this device for analytics on impressions
    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString* userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    
    NSString *model = [UIDeviceHardware platformString];
    NSString *platform = nil;
    
    if ([model containsString:@"iPad"]) {
        platform = @"iPad";
    } else if ([model containsString:@"iPhone"]) {
        platform = @"iPhone";
    } else if ([model containsString:@"iPod"]) {
        platform = @"iPod";
    }
    
    NSString* sdkVersion = [[NSBundle bundleForClass:[AYPlacement class]] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    
    // Setup session with attributes in the header
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.HTTPAdditionalHeaders = @{
                                            @"User-Agent": userAgent,
                                            @"X-Adyo-SDK-Version" : sdkVersion,
                                            @"X-Adyo-Platform": platform,
                                            @"X-Adyo-Model": model,
                                            @"X-Adyo-OS": @"iOS",
                                            @"X-Adyo-OS-Version": [[UIDevice currentDevice] systemVersion]
                                          };
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    
    // If the placement has an impression URL and a third party one, we use dispatch groups to wait for both request to finish
    dispatch_group_t group = dispatch_group_create();
    
    __block NSError *adyoError = nil;
    __block NSError *thirdPartyError = nil;
    
    // Adyo Impression
    if (_impressionUrl && _impressionUrl.length > 0) {
        
        dispatch_group_enter(group);
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_impressionUrl]];
        
        [request setHTTPMethod:@"GET"];
        
        [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            adyoError = error;
            
            dispatch_group_leave(group);
            
        }] resume];
    }
    
    // Third Party Impression
    if (_thirdPartyImpressionUrl && _thirdPartyImpressionUrl.length > 0) {
        
        dispatch_group_enter(group);
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_thirdPartyImpressionUrl]];
        
        [request setHTTPMethod:@"GET"];
        
        [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            thirdPartyError = error;
            
            dispatch_group_leave(group);
            
        }] resume];
    }
    
    // Dispatch group waits until both requests are complete
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        
        // Return failure if any of the requests failed
        if (adyoError || thirdPartyError) {
            
            if (failure) {
                failure(adyoError, thirdPartyError);
            }
            
            return;
        }
        
        
        // Return success if both requests didn't error
        if (success) {
            success();
        }
    });
}

- (NSString *)description {
    return [NSString stringWithFormat: @"<Placement: impressionUrl: %@, clickUrl: %@, creativeType: %@, creativeUrl: %@, creativeHtml: %@, refreshAfter: %.0f, thirdPartyImpressionUrl: %@, tagDomainUrl: %@>", _impressionUrl, _clickUrl, _creativeType, _creativeUrl, _creativeHtml, _refreshAfter, _thirdPartyImpressionUrl, _tagDomainUrl];
}

@end
