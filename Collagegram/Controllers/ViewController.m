//
//  ViewController.m
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import "ViewController.h"

#import <FlatUIKit/FlatUIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <AFNetworking/AFNetworking.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <AFNetworking-RACExtensions/AFHTTPRequestOperationManager+RACSupport.h>

#import "BestPhotosCrawler.h"
#import "InstaUser.h"
#import "CommonSettings.h"
#import "PhotoFetchingViewController.h"

@interface ViewController () <FUIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

@property (nonatomic) BOOL isSearching;

@end

@implementation ViewController{
    id<RACSubscriber> alertSub;
}

#pragma mark - RACSignal factories

- (RACSignal *)searchUserSignalWithUsername:(NSString *)username {
    return [self.manager rac_GET:@"https://api.instagram.com/v1/users/search"
                      parameters:@{
                                   @"q": username,
                                   @"client_id": CollagegramAppClientId
                                   }];
}

//Found something similar to what user is looking for, confirm that its the right target
- (RACSignal *)confirmUser:(InstaUser *)user {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        alertSub = subscriber;
        FUIAlertView *confirmationAlert = [CommonSettings appStyleAlertViewWithTitle:@"Пользователь не найден"
                                                                             message:[NSString stringWithFormat:@"Может быть Вы искали %@?", user.username]
                                                                            delegate:self
                                                                   cancelButtonTitle:@"Нет"
                                                                    otherButtonTitle:@"Да"];
        [confirmationAlert show];
        return [RACDisposable disposableWithBlock:^{
            [confirmationAlert dismissWithClickedButtonIndex:0
                                            animated:YES];
        }];
    }];
}

//Checking if such user can be found and if her profile is not private
- (RACSignal *)userAccountQuerySignalWithUser:(InstaUser *)user {
    NSString *userQuery = [NSString stringWithFormat:@"https://api.instagram.com/v1/users/%@", user.userId];
    return [[self.manager rac_GET:userQuery
                       parameters:@{
                                    @"client_id": CollagegramAppClientId
                                    }]
            catch:^(NSError *error) {
                if (error.code == -1011){
                    return [RACSignal error:[NSError errorWithDomain:@"UserAccountError"
                                                                code:102
                                                            userInfo:@{
                                                                       NSLocalizedFailureReasonErrorKey: @"Профиль пользователя закрыт"
                                                                       }]];
                } else {
                    return [RACSignal error:[NSError errorWithDomain:@"UserAccountError"
                                                                code:102
                                                            userInfo:@{
                                                                       NSLocalizedFailureReasonErrorKey: @"Не удалось получить информацию о пользователе"
                                                                       }]];
                }
            }];
}

- (RACSignal *)checkPhotosCountForUserAccountTuple:(RACTuple *)userTuple {
    RACTupleUnpack(AFHTTPRequestOperation *operation, NSDictionary *response) = userTuple;
    NSLog(@"Exact user account: %@", response);
    InstaUser *user = [[InstaUser alloc] initWithDictionary:response[@"data"]];
    if (user.photos < 4) {
        return [RACSignal error:[NSError errorWithDomain:@"UserAccountError"
                                                    code:103
                                                userInfo:@{
                                                           NSLocalizedFailureReasonErrorKey: @"В профиле должно быть минимум 4 фотографии"
                                                           }]];
    } else {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> sub){
            [sub sendNext:user];
            [sub sendCompleted];
            return [RACDisposable disposableWithBlock:^{}];
        }];
    }
}

#pragma mark - Actions

- (void)goGetCollageTap:(id)sender{
    __weak typeof(self)weakSelf = self;
    
    if (self.usernameField.isFirstResponder) {
        [self.usernameField resignFirstResponder];
    }
    
    self.isSearching = YES;
    
//    Show HUD
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakSelf.view
                                              animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Ищу пользователя...";
    
    NSString *usernameToQuery = weakSelf.usernameField.text;
    
    
    
    [[[self searchUserSignalWithUsername:usernameToQuery]
     flattenMap:^(RACTuple *searchTuple){
         RACTupleUnpack(AFHTTPRequestOperation *operation, NSDictionary *response) = searchTuple;
         NSArray *foundUsers = (NSArray *)response[@"data"];
         if (foundUsers.count > 0){
             InstaUser *user = [[InstaUser alloc] initWithDictionary:foundUsers[0]];
             if ([user.username isEqualToString:usernameToQuery]){
                 return [[weakSelf userAccountQuerySignalWithUser:user]
                         flattenMap:^(RACTuple *userTuple){
                             return [self checkPhotosCountForUserAccountTuple:userTuple];
                         }];
             } else {
                 return [[[self confirmUser:user]
                         flattenMap:^(id _){
                             return [weakSelf userAccountQuerySignalWithUser:user];
                         }]
                         flattenMap:^(RACTuple *userTuple){
                             return [weakSelf checkPhotosCountForUserAccountTuple:userTuple];
                         }];
             }
         } else {
             return [RACSignal error:[NSError errorWithDomain:@"UserSearchError"
                                                         code:100
                                                     userInfo:@{
                                                                NSLocalizedFailureReasonErrorKey: @"Пользователь не найден"
                                                                }]];
         }
     }]
     subscribeNext:^(InstaUser *user){
         self.selectedUser = user;
         [self performSegueWithIdentifier:@"collaging"
                                   sender:self];
     }
     error:^(NSError *error){
         NSLog(@"Error: %@", error);
         [hud hide:YES];
         self.isSearching = NO;
         NSString *msg;
         if ([error.domain isEqualToString:@"NSURLErrorDomain"]) {
             if (error.code == -1001)
                 msg = @"Не удалось связаться с Instagram";
             else if (error.code == -1009)
                 msg = @"Нет соединения с интернет";
             else
                 msg = @"Неизвестная ошибка";
         } else {
             msg = error.localizedFailureReason;
         }
         FUIAlertView *errorAlert = [CommonSettings appStyleAlertViewWithTitle:@""
                                                                       message:msg
                                                                      delegate:nil
                                                             cancelButtonTitle:@"Ок"
                                                              otherButtonTitle:nil];
         [errorAlert show];
     }
     completed:^{
         NSLog(@"Completed");
         self.isSearching = NO;
         [hud hide:YES];
     }];
}

#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.manager = [AFHTTPRequestOperationManager manager];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self)weakSelf = self;

//    Button setup
    self.getCollageBtn.buttonColor = [UIColor turquoiseColor];
    self.getCollageBtn.shadowColor = [UIColor greenSeaColor];
    self.getCollageBtn.shadowHeight = 3.0f;
    self.getCollageBtn.cornerRadius = 0.0f;
    self.getCollageBtn.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    [self.getCollageBtn setTitleColor:[UIColor cloudsColor] forState:UIControlStateNormal];
    [self.getCollageBtn setTitleColor:[UIColor cloudsColor] forState:UIControlStateHighlighted];
    
//    Text field setup
    self.usernameField.font = [UIFont flatFontOfSize:16];
    self.usernameField.backgroundColor = [UIColor clearColor];
    self.usernameField.edgeInsets = UIEdgeInsetsMake(4.0f, 15.0f, 4.0f, 15.0f);
    self.usernameField.textFieldColor = [UIColor cloudsColor];
    self.usernameField.borderColor = [UIColor turquoiseColor];
    self.usernameField.borderWidth = 2.0f;
    self.usernameField.cornerRadius = 3.0f;
    
    [self.imagesCountLabel setFont:[UIFont flatFontOfSize:20.f]];
    
//    Stepper setup
    [self.imagesCountStepper configureFlatStepperWithColor:[UIColor wisteriaColor]
                                          highlightedColor:[UIColor wisteriaColor]
                                             disabledColor:[UIColor amethystColor]
                                                 iconColor:[UIColor cloudsColor]];
    
//    Reactively
    RAC(self.imagesCountLabel, text) = [[self.imagesCountStepper rac_signalForControlEvents:UIControlEventValueChanged]
                                        map:^NSString*(UIStepper *stepper){
                                            return @(stepper.value).stringValue;
                                        }];
    
//    Enable button reactively
    RAC(self.getCollageBtn, enabled) = [RACSignal combineLatest:@[self.usernameField.rac_textSignal, RACObserve(self, isSearching)]
                                                         reduce:^(NSString *username, NSNumber *searching){
                                                             return @(username.length > 0 && ![searching boolValue]);
                                                         }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    PhotoFetchingViewController *target = segue.destinationViewController;
    [target setUser:self.selectedUser];
    [target setBestPhotosToLoad:self.imagesCountStepper.value];
}

#pragma mark - Delegation

#pragma mark Alert View

- (void)alertView:(FUIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertSub) {
        if (buttonIndex){
            [alertSub sendNext:nil];
            [alertSub sendCompleted];
        } else {
            [alertSub sendError:[NSError errorWithDomain:@"ConfirmationError"
                                                    code:101
                                                userInfo:@{
                                                           NSLocalizedFailureReasonErrorKey: @"Пользователь не найден"
                                                           }]];
        }
    }
    [alertView dismissWithClickedButtonIndex:buttonIndex
                                    animated:buttonIndex];
}

#pragma mark Text field

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.25f
                     animations:^{
                         self.descriptionView.alpha = .0f;
                         self.view.frame = CGRectOffset(self.view.frame, 0, -160.f);
                     }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.25f
                     animations:^{
                         self.descriptionView.alpha = 1.0f;
                         self.view.frame = CGRectOffset(self.view.frame, 0, 160.f);
                     }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length > 0)
        [self goGetCollageTap:nil];
    return [textField resignFirstResponder];
}

@end
