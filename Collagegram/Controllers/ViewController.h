//
//  ViewController.h
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FUIButton;
@class FUITextField;
@class InstaUser;

@interface ViewController : UIViewController

@property (nonatomic, weak) IBOutlet FUITextField *usernameField;
@property (nonatomic, weak) IBOutlet FUIButton *getCollageBtn;
@property (nonatomic, weak) IBOutlet UILabel *imagesCountLabel;
@property (nonatomic, weak) IBOutlet UITextView *descriptionView;
@property (nonatomic, weak) IBOutlet UIStepper *imagesCountStepper;

@property (nonatomic, strong) InstaUser *selectedUser;

- (IBAction)goGetCollageTap:(id)sender;

@end

