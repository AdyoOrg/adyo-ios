//
//  AYZoneView.m
//  Adyo
//
//  Created by Leon van Dyk on 2017/11/10.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import "AYZoneView.h"
#import "Adyo.h"

@import WebKit;

@interface AYZoneView() <WKNavigationDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) WKWebView *webView;
@property (assign, nonatomic) BOOL loading;
@property (assign, nonatomic) BOOL refreshScheduled;

@property (strong, nonatomic) AYPlacement *currentPlacement;
@property (strong, nonatomic) AYPlacementRequestParams *currentParams;
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;


@end

@implementation AYZoneView

- (instancetype)init {
    
    self = [super init];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
   
    
    // If placement has click URL, we don't need to intercept taps/clicks within the webview as the webview as a whole has a tap gesture to open the click URL natively
    if ([_currentPlacement.clickUrl isKindOfClass:[NSNull class]] && navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        
        // We intercept any clicks within the placement to open the URL natively
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
    
    } else if (![_currentPlacement.clickUrl isKindOfClass:[NSNull class]] && navigationAction.navigationType == WKNavigationTypeLinkActivated){
        
        // This means rich media has links but ALSO click URL, we need to cancel the navigation else the clicked link will load within the webview
        decisionHandler(WKNavigationActionPolicyCancel);
        
    } else {
        // Normal request AKA images, css etc.
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
     // This allows us to intercept the tap on a web view
    if (gestureRecognizer == _tapGestureRecognizer) {
        
        return YES;
    }
   
    return NO;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    //Prevents the webview from being zoomable when pinched
    return nil;
}

#pragma  mark - Private

- (void)setup {
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Setup webview
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    
    _webView = [[WKWebView alloc] initWithFrame:self.frame configuration:config];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    _webView.scrollView.scrollEnabled = NO;
    _webView.scrollView.delegate = self;
    _webView.opaque = NO;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.navigationDelegate = self;
    
    [self addSubview:_webView];
    
    [NSLayoutConstraint activateConstraints:@[
                                              [_webView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                              [_webView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                              [_webView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [_webView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                              ]];
    
    // Don't allow webview to scroll
    _webView.scrollView.scrollEnabled = NO;
    _webView.scrollView.bounces = NO;
    
    // Attach KVO to webview to determine if all content within webview has loaded
    [_webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)requestPlacement:(AYPlacementRequestParams *)params {

    _loading = YES;
    
    // If banner view property 'determineSize' is true, we need to determine the size right now depending on the current size of the webview
    if (_detectSize) {

        // We override the width and height of the params
        params.width = _webView.frame.size.width;
        params.height = _webView.frame.size.height;
    }
    
    // Request placement using provided params
    [Adyo requestPlacement:params success:^(BOOL found, AYPlacement *placement) {
        
        _currentPlacement = placement;
        _currentParams = params;
        
        if (!found) {
            
            if ([_delegate respondsToSelector:@selector(zoneView:didReceivePlacement:placement:)]) {
                [_delegate zoneView:self didReceivePlacement:NO placement:nil];
            }
            
            return;
        }
        
        // Depending on type, use different HTML for our webview
        NSString *html;

        if ([placement.creativeType isEqualToString:@"image"]) {
            
            html = [[NSString alloc] initWithFormat:@"%@%@%@",
                                   @"<!DOCTYPE html>"
                                   "<html>"
                                   "<head>"
                                   "<meta charset=\"UTF-8\">"
                                   "<meta name=\"viewport\" content=\"initial-scale=1.0\"/>"
                                   "<style type=\"text/css\">"
                                   "html{margin:0;padding:0;}"
                                   "body {"
                                   "margin: 0;"
                                   "padding: 0;"
                                   "font-size: 90%;"
                                   "line-height: 1.6;"
                                   "background: none;"
                                   "-webkit-touch-callout: none;"
                                   "-webkit-user-select: none;"
                                   "}"
                                   "img {"
                                   "position: absolute;"
                                   "top: 0;"
                                   "bottom: 0;"
                                   "left: 0;"
                                   "right: 0;"
                                   "margin: auto;"
                                   "max-width: 100%;"
                                   "max-height: 100%;"
                                   "background: none;"
                                   "}"
                                   "</style>"
                                   "</head>"
                                   "<body id=\"page\">"
                                   "<img src='", placement.creativeUrl, @"'/>"
                                   "</body></html>"];
        } else {
            
            html = [[NSString alloc] initWithFormat:@"%@%@%@",
                              @"<!DOCTYPE html>"
                              "<html>"
                              "<head>"
                              "<meta name=\"viewport\" content=\"initial-scale=1.0\" />"
                              "<meta charset=\"UTF-8\">"
                              "<style type=\"text/css\">"
                              "html{margin:0;padding:0;}"
                              "body {"
                              "background: none;"
                              "margin: 0;"
                              "padding: 0;"
                              "}"
                              "iframe {"
                              "width: 100%;"
                              "height: 100%;"
                              "background: none;"
                              "-webkit-touch-callout: none !important;"
                              "-webkit-user-select: none !important;"
                              "-webkit-tap-highlight-color: rgba(0,0,0,0) !important;"
                              "}"
                              "</style>"
                              "</head>"
                              "<body id=\"page\">"
                              "<iframe src='", placement.creativeUrl, @"' frameBorder=\"0\"></iframe>"
                              "</body></html>"];
        }
        
        // Load HTML into the webview on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [_webView loadHTMLString:html baseURL:nil];
        });
        
    } failure:^(NSError *error) {
        
        _loading = NO;
        
        if ([_delegate respondsToSelector:@selector(zoneView:didFailToReceivePlacement:)]) {
            [_delegate zoneView:self didFailToReceivePlacement:error];
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object change:(NSDictionary *)change
                       context:(void *)context {

    if ([keyPath isEqualToString:@"loading"] && object == _webView) {

        if (_loading && !_webView.loading) {
            
            // Disable action sheet from popping up when long pressing
            [_webView evaluateJavaScript:@"document.body.style.webkitTouchCallout='none';" completionHandler:nil];
            
            // Disable text selection
            [_webView evaluateJavaScript:@"document.body.style.webkitUserSelect='none'" completionHandler:nil];
            
            _loading = NO;
            
            // If the placement has a click url, we need to add a tap gesture recognizer to the web view a whole to intercept taps
            if (_tapGestureRecognizer) {
                
                [_webView removeGestureRecognizer:_tapGestureRecognizer];
                _tapGestureRecognizer = nil;
            }
            
            if (_currentPlacement.clickUrl && ![_currentPlacement.clickUrl isKindOfClass:[NSNull class]]) {
                
                _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(webViewTapped)];
                _tapGestureRecognizer.delegate = self;
                [_webView addGestureRecognizer:_tapGestureRecognizer];
                
            }
            
            // Let delegate know we have received the placement
            if ([_delegate respondsToSelector:@selector(zoneView:didReceivePlacement:placement:)]) {
                [_delegate zoneView:self didReceivePlacement:YES placement:_currentPlacement];
            }
            
            // Record the impression on the placement
            [_currentPlacement recordImpression:nil failure:nil];
            
            // Check if need to request a new placement in a few seconds (also don't fire a new refresh if one is already being fired
            if (_currentPlacement.refreshAfter > 0 && !_refreshScheduled) {
                
                _refreshScheduled = YES;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self performSelector:@selector(refreshPlacement) withObject:nil afterDelay:_currentPlacement.refreshAfter];
                });
            }
        }
       
    } else {
        
        // Make sure to call the superclass's implementation in the else block in case it is also implementing KVO
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)refreshPlacement {
    
    _refreshScheduled = NO;
    
    if (_currentParams) {
        
        [self requestPlacement:_currentParams];
    }
}

- (void)webViewTapped {
    
    NSURL *url = [NSURL URLWithString:_currentPlacement.clickUrl];
    
    // If url is NULL, try encoding
    if (url == nil) {
        
        NSString *encodedString = [_currentPlacement.clickUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        
        url = [NSURL URLWithString:encodedString];
    }
    
    if (url) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)reset {
    
    // We simply reset the zone view to its initial state before the request
    _currentPlacement = nil;
    _currentParams = nil;
    _loading = NO;
    _refreshScheduled = NO;
    
    if (_tapGestureRecognizer) {
        [_webView removeGestureRecognizer:_tapGestureRecognizer];
    }
    
    _tapGestureRecognizer = nil;
    
    NSString *html = [[NSString alloc] initWithFormat:
            @"<!DOCTYPE html>"
            "<html>"
            "<head>"
            "<meta charset=\"UTF-8\">"
            "<meta name=\"viewport\" content=\"initial-scale=1.0\"/>"
            "<style type=\"text/css\">"
            "html{margin:0;padding:0;}"
            "body {"
            "background: none;"
            "-webkit-touch-callout: none;"
            "-webkit-user-select: none;"
            "}"
            "</style>"
            "</head>"
            "<body>"
            "</body>"
            "</html>"];
    
    [_webView loadHTMLString:html baseURL:nil];
}

@end
