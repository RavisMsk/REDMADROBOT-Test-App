//
//  CommonSettings.h
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import <Foundation/Foundation.h>

static const NSString *CollagegramAppClientId = @"c6d96afce4f74d31b12d6db7e95d3b6f";

@class FUIAlertView;
@class FUIButton;

@interface CommonSettings : NSObject

+ (FUIAlertView *)appStyleAlertViewWithTitle:(NSString*)title
                                     message:(NSString*)msg
                                    delegate:(id)delegate
                           cancelButtonTitle:(NSString*)cancelTitle
                            otherButtonTitle:(NSString*)titles, ...;

@end
