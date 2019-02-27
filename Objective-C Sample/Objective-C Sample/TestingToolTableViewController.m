//
//  TestingToolTableViewController.m
//  Objective-C Sample
//
//  Created by Leon van Dyk on 2017/11/21.
//  Copyright © 2017 UnitX (Pty) Ltd. All rights reserved.
//

#import "TestingToolTableViewController.h"

@import Adyo;

@interface TestingToolTableViewController () <UITextFieldDelegate, AYZoneViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet AYZoneView *zoneView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;
@property (strong, nonatomic) IBOutlet UITextField *widthTextField;
@property (strong, nonatomic) IBOutlet UITextField *heightTextField;
@property (strong, nonatomic) IBOutlet UITextField *networkIdTextField;
@property (strong, nonatomic) IBOutlet UITextField *zoneIdTextField;
@property (strong, nonatomic) IBOutlet UITextField *userIdTextField;
@property (strong, nonatomic) IBOutlet UITextField *keywordsTextField;
@property (strong, nonatomic) IBOutlet UISwitch *refreshSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *displaySwitch;
@property (strong, nonatomic) IBOutlet UISwitch *recordImpressionSwitch;
@property (strong, nonatomic) IBOutlet UITextField *customPropertyTextField;
@property (strong, nonatomic) IBOutlet UITextField *customPropertyTextField2;
@property (strong, nonatomic) IBOutlet UITextField *customPropertyTextField3;
@property (strong, nonatomic) IBOutlet UITextField *customValueTextField;
@property (strong, nonatomic) IBOutlet UITextField *customValueTextField2;
@property (strong, nonatomic) IBOutlet UITextField *customValueTextField3;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *requestIndicator;
@property (strong, nonatomic) IBOutlet UIButton *requestButton;


@property (assign, nonatomic) BOOL requesting;
@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;

- (IBAction)requestButtonTapped;

@end

@implementation TestingToolTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set width annd height textfield to constants set by storyboard
    _widthTextField.text = [NSString stringWithFormat: @"%.0f", _widthConstraint.constant];
    _heightTextField.text = [NSString stringWithFormat: @"%.0f", _heightConstraint.constant];
    
    // Hook up tap gesture to hide keyboard when tapping away
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    _tapRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:_tapRecognizer];
    
    // Hookup to zone events
    _zoneView.delegate = self;
    
    // Let the zone view send its width and height at the moment of the request and not use the dimensions specified in the API
    _zoneView.detectSize = YES;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    // Change the width or height of the zone
    if (textField == _widthTextField) {
        
        if (_widthTextField.text.floatValue <= 0) {
            _widthTextField.text = @"1";
        }
        
        _widthConstraint.constant = textField.text.floatValue;
        [_zoneView layoutIfNeeded];
    } else if (textField == _heightTextField) {
        
        if (_heightTextField.text.floatValue <= 0) {
            _heightTextField.text = @"1";
        }
        
        _heightConstraint.constant = textField.text.floatValue;
        [_zoneView layoutIfNeeded];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if (gestureRecognizer == _tapRecognizer) {
        
        return YES;
    }
    
    return NO;
}

#pragma mark - AYZoneViewDelegate

- (void)zoneView:(AYZoneView *)zoneView didReceivePlacement:(BOOL)found placement:(AYPlacement *)placement {
    
    _requesting = NO;
    _requestIndicator.hidden = YES;
    _requestButton.hidden = NO;
    
    
    if (!found) {
        [self showAlertWithTitle:@"No Placements" andBody:@"The request succeeded but no placements were found for the provided parameters."];
    }
}

- (void)zoneView:(AYZoneView *)zoneView didFailToReceivePlacement:(NSError *)error {
    
    _requesting = NO;
    _requestIndicator.hidden = YES;
    _requestButton.hidden = NO;
    
    [self showAlertWithTitle:@"Request Failed" andBody:error.localizedDescription];
}

- (BOOL)zoneView:(AYZoneView *)zoneView shouldRefreshForPlacement:(AYPlacement *)placement {
    
    return [_refreshSwitch isOn];
}

- (BOOL)zoneView:(AYZoneView *)zoneView shouldDisplayPlacement:(AYPlacement *)placement {
    
    return [_displaySwitch isOn];
}

- (BOOL)zoneView:(AYZoneView *)zoneView shouldRecordImpressionForPlacement:(AYPlacement *)placement {
    
    return [_recordImpressionSwitch isOn];
}

#pragma mark - Private

- (void)requestPlacement {
    
    // Validation
    if (_networkIdTextField.text.length == 0) {
        return [self showAlertWithTitle:@"Network ID Required" andBody:@"Please provide a network ID."];
    }
    
    if (_zoneIdTextField.text.length == 0) {
        return [self showAlertWithTitle:@"Zone ID Required" andBody:@"Please provide a zone ID."];
    }
    
    if ((_customValueTextField.text.length > 0 && _customPropertyTextField.text.length == 0) ||
        (_customValueTextField2.text.length > 0 && _customPropertyTextField2.text.length == 0) ||
        (_customValueTextField3.text.length > 0 && _customPropertyTextField3.text.length == 0)) {
        return [self showAlertWithTitle:@"Property Name Required" andBody:@"Custom properties cannot have empty property names."];
    }
    
    if ((_customPropertyTextField.text.length > 0 && _customValueTextField.text.length == 0) ||
        (_customPropertyTextField2.text.length > 0 && _customValueTextField2.text.length == 0) ||
        (_customPropertyTextField3.text.length > 0 && _customValueTextField3.text.length == 0)) {
        return [self showAlertWithTitle:@"Custom Value Required" andBody:@"Custom properties cannot have empty values."];
    }
    
    // Setup params
    AYPlacementRequestParams *params = [[AYPlacementRequestParams alloc] init];
    params.networkId = _networkIdTextField.text.integerValue;
    params.zoneId = _zoneIdTextField.text.integerValue;
    
    if (_userIdTextField.text.length > 0) {
        params.userId = _userIdTextField.text;
    }
    
    if (_keywordsTextField.text.length > 0) {
        params.keywords = [[_keywordsTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@","];
    }
    
    NSMutableDictionary *custom = [[NSMutableDictionary alloc] init];
    
    if (_customPropertyTextField.text.length > 0) {
        custom[_customPropertyTextField.text] = _customValueTextField.text;
    }
    
    if (_customPropertyTextField2.text.length > 0) {
        custom[_customPropertyTextField2.text] = _customValueTextField2.text;
    }
    
    if (_customPropertyTextField3.text.length > 0) {
        custom[_customPropertyTextField3.text] = _customValueTextField3.text;
    }
    
    if (custom.count > 0) {
        params.custom = custom;
    }
    
    // Execute the request
    _requesting = YES;
    _requestButton.hidden = YES;
    _requestIndicator.hidden = NO;
    
    [_zoneView requestPlacement:params];
}

- (void)hideKeyboard {
    
    [self.view endEditing:YES];
}

- (void)showAlertWithTitle:(NSString *)title andBody:(NSString *)body {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:body preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)requestButtonTapped {
    
    if (!_requesting) {
        [self requestPlacement];
    }
}

@end
