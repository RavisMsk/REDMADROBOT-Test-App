//
//  CollageViewController.m
//  Collagegram
//
//  Created by Nikita Anisimov on 31/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import "CollageViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <FlatUIKit/FlatUIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <MessageUI/MessageUI.h>

#import "CommonSettings.h"

@interface CollageViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *collageImgView;
@property (nonatomic, weak) IBOutlet FUIButton *sendByEmailBtn;
@property (nonatomic, weak) IBOutlet FUIButton *saveToPhotosBtn;
@property (nonatomic, weak) IBOutlet FUIButton *backBtn;

@end

@implementation CollageViewController {
    id<RACSubscriber> imageSavingSub;
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (contextInfo) {
        id<RACSubscriber> sub = CFBridgingRelease(contextInfo);
        if (error)
            [sub sendError:error];
        else
            [sub sendCompleted];
    }
}

- (void)mailingSuccessHUD {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view
                                              animated:YES];
    hud.mode = MBProgressHUDModeCustomView;
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
    hud.labelText = @"Отправлено";
    [hud hide:YES afterDelay:2.0f];
}

- (void)mailingFailureAlert {
    [[CommonSettings appStyleAlertViewWithTitle:@"Не удалось"
                                        message:@"Ошибка при отправке коллажа по e-mail"
                                       delegate:nil
                              cancelButtonTitle:@"Жаль"
                               otherButtonTitle:nil] show];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self)weakSelf = self;
    
    self.collageImgView.image = self.collageImg;
    
//    Buttons setup
    self.backBtn.buttonColor = [UIColor alizarinColor];
    self.backBtn.shadowColor = [UIColor pomegranateColor];
    self.backBtn.shadowHeight = 3.0f;
    self.backBtn.cornerRadius = 0.0f;
    self.backBtn.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    [self.backBtn setTitleColor:[UIColor cloudsColor] forState:UIControlStateNormal];
    [self.backBtn setTitleColor:[UIColor cloudsColor] forState:UIControlStateHighlighted];
    self.backBtn.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal*(id _){
        [weakSelf dismissViewControllerAnimated:YES
                                     completion:nil];
        return [RACSignal empty];
    }];
    
    self.sendByEmailBtn.buttonColor = [UIColor turquoiseColor];
    self.sendByEmailBtn.shadowColor = [UIColor greenSeaColor];
    self.sendByEmailBtn.shadowHeight = 3.0f;
    self.sendByEmailBtn.cornerRadius = 0.0f;
    self.sendByEmailBtn.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    [self.sendByEmailBtn setTitleColor:[UIColor cloudsColor] forState:UIControlStateNormal];
    [self.sendByEmailBtn setTitleColor:[UIColor cloudsColor] forState:UIControlStateHighlighted];
    self.sendByEmailBtn.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal*(id _){
//        Get data for png image
        NSData *imageData = UIImagePNGRepresentation(weakSelf.collageImg);
        
        if ([MFMailComposeViewController canSendMail]){
            MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            controller.navigationBar.tintColor = [UIColor turquoiseColor];
            [controller setSubject:@"Collagegram. Коллаж лучших фотографий."];
            [controller setMessageBody:@"Коллаж из Ваших лучших фотографий!"
                                isHTML:NO];
            [controller addAttachmentData:imageData
                                 mimeType:@"image/png"
                                 fileName:@"collage.png"];
            [self presentViewController:controller
                               animated:YES
                             completion:nil];
        } else {
            [[CommonSettings appStyleAlertViewWithTitle:@"Не удалось отправить"
                                                message:@"Ваш почтовый клиент не настроен"
                                               delegate:nil
                                      cancelButtonTitle:@"Жаль"
                                       otherButtonTitle:nil] show];
        }
        
        return [RACSignal empty];
    }];
    
    self.saveToPhotosBtn.buttonColor = [UIColor emerlandColor];
    self.saveToPhotosBtn.shadowColor = [UIColor nephritisColor];
    self.saveToPhotosBtn.shadowHeight = 3.0f;
    self.saveToPhotosBtn.cornerRadius = 0.0f;
    self.saveToPhotosBtn.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    [self.saveToPhotosBtn setTitleColor:[UIColor cloudsColor] forState:UIControlStateNormal];
    [self.saveToPhotosBtn setTitleColor:[UIColor cloudsColor] forState:UIControlStateHighlighted];
    self.saveToPhotosBtn.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal*(id _){
//        Show progress indicator hud
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakSelf.view
                                                  animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Сохраняю коллаж...";
//        Create signal for saving photo
        return [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> sub){
            UIImageWriteToSavedPhotosAlbum(weakSelf.collageImg,
                                           self,
                                           @selector(image:didFinishSavingWithError:contextInfo:),
                                           (void *)CFBridgingRetain(sub));
            return [RACDisposable disposableWithBlock:^{
                //Not cancellable saving operation...
            }];
        }] doCompleted:^{
            hud.mode = MBProgressHUDModeCustomView;
            hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark"]];
            hud.labelText = @"Сохранено";
            [hud hide:YES afterDelay:2.0f];
        }] doError:^(NSError *error){
            [hud hide:YES];
            [[CommonSettings appStyleAlertViewWithTitle:@"Ошибка"
                                                message:@"Не удалось сохранить фотографию"
                                               delegate:nil
                                      cancelButtonTitle:@"Жаль"
                                       otherButtonTitle:nil] show];
        }];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Delegation

#pragma mark Mail composer

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error{
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"Collage mailing cancelled.");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Collage sent!");
            [self mailingSuccessHUD];
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Collage mailing failed! %@", error);
            [self mailingFailureAlert];
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Collage saved?");
            break;
        default:
            break;
    }
    [controller dismissViewControllerAnimated:YES
                                   completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
