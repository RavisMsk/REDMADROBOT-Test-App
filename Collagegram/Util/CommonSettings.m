//
//  CommonSettings.m
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import "CommonSettings.h"

#import <FlatUIKit/FlatUIKit.h>

@implementation CommonSettings

+ (FUIAlertView *)appStyleAlertViewWithTitle:(NSString *)title
                                     message:(NSString *)msg
                                    delegate:(id)delegate
                           cancelButtonTitle:(NSString *)cancelTitle
                            otherButtonTitle:(NSString *)titles, ... {
    FUIAlertView *alertView = [[FUIAlertView alloc] initWithTitle:title
                                                          message:msg
                                                         delegate:delegate
                                                cancelButtonTitle:cancelTitle
                                                otherButtonTitles:titles, nil];
    alertView.titleLabel.textColor = [UIColor cloudsColor];
    alertView.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    alertView.messageLabel.textColor = [UIColor cloudsColor];
    alertView.messageLabel.font = [UIFont flatFontOfSize:14];
    alertView.backgroundOverlay.backgroundColor = [[UIColor cloudsColor] colorWithAlphaComponent:0.8];
    alertView.alertContainer.backgroundColor = [UIColor midnightBlueColor];
    alertView.defaultButtonColor = [UIColor cloudsColor];
    alertView.defaultButtonShadowColor = [UIColor asbestosColor];
    alertView.defaultButtonFont = [UIFont boldFlatFontOfSize:16];
    alertView.defaultButtonTitleColor = [UIColor asbestosColor];
    return alertView;
}

@end
