//
//  AYZoneView.m
//  Adyo
//
//  Created by Leon van Dyk on 2017/11/10.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import "AYZoneView.h"
#import "Adyo.h"
#import "AYPopupViewController.h"

@import WebKit;
@import SafariServices;

@interface AYZoneView() <WKNavigationDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, SFSafariViewControllerDelegate>

@property (strong, nonatomic) WKWebView *webView;

@property (assign, nonatomic) BOOL loading;
@property (assign, nonatomic) BOOL refreshScheduled;
@property (assign, nonatomic) BOOL appIsMinimized;

@property (strong, nonatomic) AYPlacement *currentPlacement;
@property (strong, nonatomic) AYPlacementRequestParams *currentParams;
@property (strong, nonatomic) NSArray<AYPlacementRequestParams *> *availableParams;
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

// Popup related
@property (strong, nonatomic) AYPopupViewController *popupViewController;
@property (strong, nonatomic) WKWebView *popupWebView;
@property (assign, nonatomic) float currentPopupContentHeight;
@property (assign, nonatomic) float currentPopupContentWidth;

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

- (void)dealloc {
    [_webView removeObserver:self forKeyPath:@"loading"];
    _webView.scrollView.delegate = nil;
    _webView.navigationDelegate = nil;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
    // Only used for popup view to get height of content
    if (webView != _popupWebView) {
        return;
    }
    
    _popupViewController.activityIndicator.hidden = YES;
    [_popupViewController.activityIndicator stopAnimating];
   
    // Only detect and resize popup wrapper if set to
    if (_popupScalesToContent) {
        [_popupWebView evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            
            self.currentPopupContentHeight = [result floatValue] + 38; // Constant of 38 works well compared to using height of navigation bar (which is 44).
            [self refreshPopupConstraints];
        }];
        
        [_popupWebView evaluateJavaScript:@"document.body.scrollWidth" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            
            self.currentPopupContentWidth = [result floatValue];
            [self refreshPopupConstraints];
        }];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
   
    // Check if content webview or main content web view
    if (webView == _popupWebView) {
        decisionHandler(WKNavigationActionPolicyAllow);

        return;
    }

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

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma  mark - Private

- (void)setup {
    
    self.userInteractionEnabled = NO;
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
    
    // Setup popup view related members
    _currentPopupContentWidth = 400;
    _currentPopupContentHeight = 250;
    _popupCornerRadius = 6.0f;
    _popupScalesToContent = YES;
    _popupShowLoader = YES;
    _popupInitialWidth = 400;
    _popupInitialHeight = 250;
    
    // Listen for app 'minimizing' determine whether to rotate
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidMinimize)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidMinimize)
                                                 name:UIApplicationWillResignActiveNotification
                                               object: nil];
    
    // Listen for app 'maximizing' determine whether to rotate
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidMaximize)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidMaximize)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object: nil];
    
    
}

- (void)requestSinglePlacement:(AYPlacementRequestParams *)params {
   
    _paused = NO;
    _loading = YES;
    
    // If banner view property 'determineSize' is true, we need to determine the size right now depending on the current size of the webview
    if (_detectSize) {

        // We override the width and height of the params
        params.width = _webView.frame.size.width;
        params.height = _webView.frame.size.height;
    }
    
    // We only want to request placements for creative we support
    params.creativeTypes = @[@"image", @"rich-media", @"tag"];
    
    // Request placement using provided params
    [Adyo requestPlacement:params success:^(BOOL found, AYPlacement *placement) {
        
        // If no placement found AND there is no placement from previous request, then disable interaction so touches can pass through it
        if (!found && !self.currentPlacement) {
            self.userInteractionEnabled = NO;
        }
        
        self.currentPlacement = placement;
        self.currentParams = params;
       
        if (!found) {
            
            if ([self.delegate respondsToSelector:@selector(zoneView:didReceivePlacement:placement:)]) {
                [self.delegate zoneView:self didReceivePlacement:NO placement:nil];
            }
            
            return;
        }
        
        // Depending on type, use different HTML for our webview
        NSString *html = @"";

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
            
        } else if ([placement.creativeType isEqualToString:@"rich-media"]) {
            
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
            
        } else if ([placement.creativeType isEqualToString:@"tag"]) {
            
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
                    , placement.creativeHtml,
                    @"</body></html>"];
        }
        
        // Load HTML into the webview on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webView loadHTMLString:html baseURL:placement.tagDomainUrl];
        });
        
    } failure:^(NSError *error) {
        
        self.loading = NO;
        
        if ([self.delegate respondsToSelector:@selector(zoneView:didFailToReceivePlacement:)]) {
            [self.delegate zoneView:self didFailToReceivePlacement:error];
        }
    }];
}


- (void)requestPlacement:(AYPlacementRequestParams *)params {
    
    _availableParams = nil; // Incase switching from random params to single params.
    
    [self requestSinglePlacement:params];
}

- (void)requestRandomPlacement:(NSArray<AYPlacementRequestParams *> *)params {
    
    _availableParams = params;
    
    // If provided params is empty, do nothing
    if (_availableParams == nil || _availableParams.count == 0) {
        
        return;
    }

    AYPlacementRequestParams *randomParams = [self getRandomAvailableParams];
    
    [self requestSinglePlacement:randomParams];
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
            
            // Enable interaction again so taps don't pass through it
            self.userInteractionEnabled = YES;
            
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
                    [self performSelector:@selector(refreshPlacement) withObject:nil afterDelay:self.currentPlacement.refreshAfter];
                });
            }
        }
       
    } else {
        
        // Make sure to call the superclass's implementation in the else block in case it is also implementing KVO
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)refreshPlacement {
    
    // Check if we are not paused and app is open
    if (!_paused && !_appIsMinimized) {
        
        _refreshScheduled = NO;
        
        // Use current params or random available params if set
        if (_availableParams && _availableParams.count > 0) {
            [self requestSinglePlacement:[self getRandomAvailableParams]];
        } else if (_currentParams) {
            [self requestSinglePlacement:_currentParams];
        }
    } else {
        [self performSelector:@selector(refreshPlacement) withObject:nil afterDelay:5];
    }
}

- (void)webViewTapped {
    
    // Don't do anything if click url is null
    if (!_currentPlacement.clickUrl || _currentPlacement.clickUrl.length == 0) {
        return;
    }
    
    // Get NSURL out of click url string
    NSURL *url = [NSURL URLWithString:_currentPlacement.clickUrl];
    
    // If url is NULL, try encoding
    if (url == nil) {
        
        NSString *encodedString = [_currentPlacement.clickUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        
        url = [NSURL URLWithString:encodedString];
    }
    
    if (!url) {
        return;
    }
    
    // Depending on the target of the placement, we either open the destination url via SFSafariViewController, in-app popup, or default change to browser
    if ([_currentPlacement.target isEqualToString:@"inside"]) {
        [self openURLInside:url];
    } else if ([_currentPlacement.target isEqualToString:@"popup"]) {
        [self openURLWithPopup:url];
    } else {
        [[UIApplication sharedApplication] openURL:url]; // Default open Safari
    }
}

- (void)openURLInside:(NSURL *)url {
    
    // Open URL using Safari view controller
    SFSafariViewController *sf = [[SFSafariViewController alloc] initWithURL:url];
    sf.delegate = self;
    
    // Get view controller this view is on
    UIViewController *parentViewController = _popupPresentingViewController ? _popupPresentingViewController : [self parentViewController];
    
    // If we cannot find it then just open using Safari
    if (!parentViewController) {
        [[UIApplication sharedApplication] openURL:url];
        
        return;
    }
    
    [parentViewController presentViewController:sf animated:YES completion:nil];
}

- (void)openURLWithPopup:(NSURL *)url {
    
    // Get view controller this view is on
    UIViewController *parentViewController = _popupPresentingViewController ? _popupPresentingViewController : [self parentViewController];

    // If we cannot find it then just open using Safari
    if (!parentViewController) {
        [[UIApplication sharedApplication] openURL:url];

        return;
    }
    
    // Load pop up view controller from nib and configure
    NSBundle *bundle  = [NSBundle bundleForClass:[AYZoneView class]];
    _popupViewController = [[AYPopupViewController alloc] initWithNibName:NSStringFromClass([AYPopupViewController class]) bundle:bundle];
    
    _popupViewController.modalPresentationStyle = (_popupPresentationStyle) ? _popupPresentationStyle : UIModalPresentationOverCurrentContext;
    _popupViewController.modalTransitionStyle = (_popupTransitionStyle) ? _popupTransitionStyle : UIModalTransitionStyleCrossDissolve;
    
    _popupViewController.wrapperInitialWidth = _popupInitialWidth;
    _popupViewController.wrapperInitialHeight = _popupInitialHeight;
    _popupViewController.wrapperCornerRadius = _popupCornerRadius;
    _popupViewController.showLoader = _popupShowLoader;
    _popupViewController.overlayColor = _popupOverlayColor;
    _popupViewController.backgroundColor = _popupBackgroundColor;
    _popupViewController.doneButtonTintColor = _popupDoneButtonTintColor;
    _popupViewController.barTintColor = _popupBarTintColor;
    _popupViewController.doneButtonText = _popupDoneButtonText;
    
    // Setup webview that will display click url content
    _popupWebView = [[WKWebView alloc] init];
    _popupWebView.navigationDelegate = self;
    _popupWebView.translatesAutoresizingMaskIntoConstraints = NO;
    [_popupWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
    // Add webview programatically because storyboard method is broken until ios 11
    [parentViewController presentViewController:_popupViewController animated:YES completion:^{
        
        // IBOutlets are nil until view controller is display, hence do all outlet related stuff in completion block
        [self.popupViewController.webViewContainerView addSubview:self.popupWebView];
        
        [NSLayoutConstraint activateConstraints:@[
                                                  [self.popupWebView.leadingAnchor constraintEqualToAnchor:self.popupViewController.webViewContainerView.leadingAnchor],
                                                  [self.popupWebView.trailingAnchor constraintEqualToAnchor:self.popupViewController.webViewContainerView.trailingAnchor],
                                                  [self.popupWebView.topAnchor constraintEqualToAnchor:self.popupViewController.webViewContainerView.topAnchor],
                                                  [self.popupWebView.bottomAnchor constraintEqualToAnchor:self.popupViewController.webViewContainerView.bottomAnchor],
                                                ]];
    }];
}

- (void)reset {
    
    // We simply reset the zone view to its initial state before the request
    self.userInteractionEnabled = NO;
    _currentPlacement = nil;
    _currentParams = nil;
    _availableParams = nil;
    _loading = NO;
    _refreshScheduled = NO;
    
    if (_tapGestureRecognizer) {
        [_webView removeGestureRecognizer:_tapGestureRecognizer];
    }
    
    _tapGestureRecognizer = nil;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshPlacement) object:nil];
    
//    NSString *html = [[NSString alloc] initWithFormat:
//            @"<!DOCTYPE html>"
//            "<html>"
//            "<head>"
//            "<meta charset=\"UTF-8\">"
//            "<meta name=\"viewport\" content=\"initial-scale=1.0\"/>"
//            "<style type=\"text/css\">"
//            "html{margin:0;padding:0;}"
//            "body {"
//            "background: none;"
//            "-webkit-touch-callout: none;"
//            "-webkit-user-select: none;"
//            "}"
//            "</style>"
//            "</head>"
//            "<body>"
//            "</body>"
//            "</html>"];
//    
//    [_webView loadHTMLString:html baseURL:nil];
}

- (void)resume:(BOOL)immediately {
    _paused = NO;
    
    // If resume immediately, cancel refresh check and refresh
    if (immediately) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshPlacement) object:nil];
        [self refreshPlacement];
    }
}

- (void)pause {
    _paused = YES;
}

- (void)appDidMinimize {
    _appIsMinimized = YES;
}

- (void)appDidMaximize {
    _appIsMinimized = NO;
}

- (void)refreshPopupConstraints {
    
    if (_popupViewController == nil) {
        return;
    }
    
    // Popup view controllers resize to the content of its webview
    _popupViewController.wrapperWidthConstraint.constant = _currentPopupContentWidth;
    _popupViewController.wrapperHeightConstraint.constant = _currentPopupContentHeight;
    
    [_popupViewController.view layoutIfNeeded];
}

- (UIViewController *)parentViewController {
    
    
    // Try find the view controller that this view is in
    UIResponder *responder = self;
    
    while (![responder isKindOfClass:[UIViewController class]]) {
        responder = [responder nextResponder];
        
        if (nil == responder) {
            break;
        }
    }
    
    return (UIViewController *)responder;
}

- (AYPlacementRequestParams *)getRandomAvailableParams {
    
    NSUInteger randomIndex = arc4random() % _availableParams.count;
    
    return [_availableParams objectAtIndex:randomIndex];
}

@end
