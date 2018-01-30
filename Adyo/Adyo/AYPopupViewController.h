//
//  AYPopupViewController.h
//  Adyo
//
//  Created by Leon van Dyk on 2018/01/29.
//  Copyright © 2018 UnitX (Pty) Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AYPopupViewController : UIViewController

@property (assign, nonatomic) float wrapperInitialWidth;
@property (assign, nonatomic) float wrapperInitialHeight;
@property (assign, nonatomic) float wrapperCornerRadius;
@property (assign, nonatomic) BOOL showLoader;
@property (strong, nonatomic) UIColor *overlayColor;
@property (strong, nonatomic) UIColor *backgroundColor;
@property (strong, nonatomic) UIColor *doneButtonTintColor;
@property (strong, nonatomic) UIColor *barTintColor;
@property (strong, nonatomic) NSString *doneButtonText;

@property (strong, nonatomic) IBOutlet UIView *wrapperView;
@property (strong, nonatomic) IBOutlet UIView *webViewContainerView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *wrapperWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *wrapperHeightConstraint;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;

@end
