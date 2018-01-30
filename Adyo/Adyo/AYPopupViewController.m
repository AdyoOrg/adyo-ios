//
//  AYPopupViewController.m
//  Adyo
//
//  Created by Leon van Dyk on 2018/01/29.
//  Copyright © 2018 UnitX (Pty) Ltd. All rights reserved.
//

#import "AYPopupViewController.h"

@interface AYPopupViewController ()

- (IBAction)closeButtonTapped;

@end

@implementation AYPopupViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _wrapperView.layer.cornerRadius = _wrapperCornerRadius;
    
    _activityIndicator.hidden = !_showLoader;
    
    if (_overlayColor) {
        self.view.backgroundColor = _overlayColor;
    }
    
    if (_backgroundColor) {
        _wrapperView.backgroundColor = _backgroundColor;
    }
    
    if (_doneButtonTintColor) {
        _doneButton.tintColor = _doneButtonTintColor;
    }
    
    if (_barTintColor) {
        _navigationBar.barTintColor = _barTintColor;
    }
    
    if (_doneButtonText) {
        _doneButton.title = _doneButtonText;
    }
    
    _wrapperWidthConstraint.constant = _wrapperInitialWidth;
    _wrapperHeightConstraint.constant = _wrapperInitialHeight;
    
    [self.view layoutIfNeeded];
}

- (IBAction)closeButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
