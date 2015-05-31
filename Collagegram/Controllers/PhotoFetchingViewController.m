//
//  PhotoFetchingViewController.m
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import "PhotoFetchingViewController.h"

#import <ObjectiveSugar/ObjectiveSugar.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking-RACExtensions/AFHTTPRequestOperationManager+RACSupport.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <FlatUIKit/FlatUIKit.h>

#import "CollageViewController.h"
#import "BestPhotosCrawler.h"
#import "InstaUser.h"
#import "Photo.h"
#import "CommonSettings.h"

@interface PhotoFetchingViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *fullnameLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *photosCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *chosenLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImgView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *avatarLoadingIndicator;
@property (weak, nonatomic) IBOutlet UICollectionView *photosCollectionView;
@property (weak, nonatomic) IBOutlet FUIButton *makeCollageBtn;
@property (weak, nonatomic) IBOutlet FUIButton *cancelBtn;

@property (nonatomic, strong) NSMutableArray *bestPhotos;
@property (nonatomic, strong) NSMutableArray *selectedPhotos;
@property (nonatomic) BOOL selectionAllowed;
@property (nonatomic, strong) UIImage *resultingImage;

@end

@implementation PhotoFetchingViewController

#pragma mark - Private

- (RACSignal *)fetchPhotos:(NSArray *)photos {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager setResponseSerializer: [AFImageResponseSerializer serializer]];
        
        NSArray *signalsArray = [photos map:^RACSignal *(Photo *photo){
            return [manager rac_GET:photo.highResPhotoUrl.absoluteString
                         parameters:nil];
        }];
        [[RACSignal merge:signalsArray]
         subscribeNext:^(RACTuple *imgTuple){
             RACTupleUnpack(AFHTTPRequestOperation *operation, id response) = imgTuple;
             [subscriber sendNext:response];
         }
         error:^(NSError *error){
             [subscriber sendError:error];
         }
         completed:^{
             [subscriber sendCompleted];
         }];

        return [RACDisposable disposableWithBlock:^{
            
        }];
    }];
}

#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.bestPhotos = [NSMutableArray new];
        self.selectedPhotos = [NSMutableArray new];
        self.selectionAllowed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self)weakSelf = self;
    
//   Make collage button setup
    self.makeCollageBtn.buttonColor = [UIColor turquoiseColor];
    self.makeCollageBtn.shadowColor = [UIColor greenSeaColor];
    self.makeCollageBtn.shadowHeight = 3.0f;
    self.makeCollageBtn.cornerRadius = 0.0f;
    self.makeCollageBtn.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    self.makeCollageBtn.enabled = NO;
    [self.makeCollageBtn setTitleColor:[UIColor cloudsColor] forState:UIControlStateNormal];
    [self.makeCollageBtn setTitleColor:[UIColor cloudsColor] forState:UIControlStateHighlighted];
    self.makeCollageBtn.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal*(id _){
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakSelf.view
                                                  animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Собираю коллаж...";
        
//        The size is hard-coded due to only one collage template
        CGFloat size = 1280;
//
        UIGraphicsBeginImageContext(CGSizeMake(size, size));
        CGContextRef currentContext = UIGraphicsGetCurrentContext();
        
//        Iterating photos and drawing them on context
        [weakSelf.selectedPhotos eachWithIndex:^(UIImage *photo, NSUInteger i) {
            //create a rect equivalent to the full size of the image
            CGRect drawRect = CGRectMake(i%2 * size/2,
                                         i/2 * size/2,
                                         size/2, size/2);
            
            //draw the image to our clipped context using our offset rect
            [photo drawInRect:drawRect];
        }];
        
        //pull the image from our cropped context
        UIImage *collage = UIGraphicsGetImageFromCurrentImageContext();
        
        //pop the context to get back to the default
        UIGraphicsEndImageContext();
        
        [hud hide:YES];
        
        weakSelf.resultingImage = collage;
        [weakSelf performSegueWithIdentifier:@"toResult"
                                      sender:weakSelf];
        
        return [RACSignal empty];
    }];
    
//    Cancel btn
    self.cancelBtn.buttonColor = [UIColor alizarinColor];
    self.cancelBtn.shadowColor = [UIColor pomegranateColor];
    self.cancelBtn.shadowHeight = 3.0f;
    self.cancelBtn.cornerRadius = 0.0f;
    self.cancelBtn.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    [self.cancelBtn setTitleColor:[UIColor cloudsColor] forState:UIControlStateNormal];
    [self.cancelBtn setTitleColor:[UIColor cloudsColor] forState:UIControlStateHighlighted];
    
    self.cancelBtn.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal*(id _){
        [weakSelf dismissViewControllerAnimated:YES
                                     completion:nil];
        return [RACSignal empty];
    }];
    
//    User profile data
    self.fullnameLabel.text = self.user.fullname;
    self.usernameLabel.text = self.user.username;
    self.photosCountLabel.text = [NSString stringWithFormat:@"%lu %@", self.user.photos, self.user.photos < 5 ? @"фотки" : @"фоток"];
//    Avatar img
    self.avatarImgView.layer.cornerRadius = 36.f;
    self.avatarImgView.layer.masksToBounds = YES;
    self.avatarImgView.backgroundColor = [UIColor wetAsphaltColor];
    
//    Selected photos count is visible only when > 4 photos fetched
    self.chosenLabel.alpha = self.bestPhotosToLoad == 4 ? 0.0f : 1.0f;
    
//    CollectionView setup
    [self.photosCollectionView registerClass:[UICollectionViewCell class]
                  forCellWithReuseIdentifier:@"PhotoCollectionCellId"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    __weak typeof(self)weakSelf = self;
    
    if (self.bestPhotos.count > 0) return;
    
    //    Start loading avatar
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFImageResponseSerializer serializer];
    [[manager rac_GET:self.user.avatarUrl.absoluteString
           parameters:nil]
     subscribeNext:^(RACTuple *avatarTuple){
         RACTupleUnpack(AFHTTPRequestOperation *operation, id response) = avatarTuple;
         weakSelf.avatarImgView.image = response;
         [weakSelf.avatarLoadingIndicator stopAnimating];
     }];
    
    //    Show indicator for photos crawling
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view
                                              animated:YES];
    hud.mode = MBProgressHUDModeAnnularDeterminate;
    hud.labelText = @"Выбираю самые крутые фотки...";
    //    Create crawler
    BestPhotosHandler bestPhotosHandler = ^(NSArray *bestPhotos) {
        NSLog(@"Fetched best photos: %@", bestPhotos);
        hud.progress = 0.f;
        hud.labelText = @"Загружаю фотки...";
        [[weakSelf fetchPhotos:bestPhotos]
         subscribeNext:^(UIImage *img){
             [weakSelf.bestPhotos push:img];
             if (weakSelf.bestPhotosToLoad == 4)
                 [weakSelf.selectedPhotos push:img];
             [weakSelf.photosCollectionView reloadData];
             hud.progress += 1.f/4.f;
         }
         error:^(NSError *error){
             NSLog(@"Error while loading photo");
             NSString *msg;
             if ([error.domain isEqualToString:@"NSURLErrorDomain"]){
                 if (error.code == -1001)
                     msg = @"Не удалось загрузить фотографию";
                 else if (error.code == -1009)
                     msg = @"Нет соединения с интернет";
                 else
                     msg = @"Неизвестная ошибка";
             } else {
                 msg = error.localizedFailureReason;
             }
             [hud hide:YES];
             [[CommonSettings appStyleAlertViewWithTitle:@"Ошибка"
                                                 message:msg
                                                delegate:self
                                       cancelButtonTitle:@"Ок"
                                        otherButtonTitle:nil] show];
         }
         completed:^{
             NSLog(@"Loaded all photos");
             weakSelf.makeCollageBtn.enabled = weakSelf.selectedPhotos.count == 4;
             [hud hide:YES];
         }];
    };
    BestPhotosCrawler *crawler = [BestPhotosCrawler crawlerForBestPhotosForUserId:self.user.userId
                                                                   numberOfPhotos:self.bestPhotosToLoad
                                                                bestPhotosHandler:bestPhotosHandler
                                                                  progressHandler:^(NSUInteger progress){
                                                                      hud.progress = ((float)progress) / weakSelf.user.photos;
                                                                  }
                                                                     errorHandler:^(NSError *error){
                                                                         NSLog(@"Photo crawling error: %@", error);
                                                                         NSString *msg;
                                                                         if ([error.domain isEqualToString:@"NSURLErrorDomain"]){
                                                                             if (error.code == -1001)
                                                                                 msg = @"Не удалось связаться с Instagram";
                                                                             else if (error.code == -1009)
                                                                                 msg = @"Нет соединения с интернет";
                                                                             else
                                                                                 msg = @"Неизвестная ошибка";
                                                                         } else {
                                                                             msg = error.localizedFailureReason;
                                                                         }
                                                                         [hud hide:YES];
                                                                         [[CommonSettings appStyleAlertViewWithTitle:@"Ошибка"
                                                                                                             message:msg
                                                                                                            delegate:self
                                                                                                   cancelButtonTitle:@"Ок"
                                                                                                    otherButtonTitle:nil] show];
                                                                     }];
    
    //    Run it!
    [crawler crawl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Delegation

#pragma mark Alert view

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [alertView dismissWithClickedButtonIndex:buttonIndex
                                    animated:NO];
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

#pragma mark Collection view

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.bestPhotos.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat viewWidth = CGRectGetWidth(collectionView.bounds) - 10.f;
    return CGSizeMake(viewWidth/2., viewWidth/2.);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat viewWidth = CGRectGetWidth(collectionView.bounds) - 10.f;
    const static CGFloat cellBorder = 5.f;
    
    static NSString *cellId = @"PhotoCollectionCellId";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId
                                                                           forIndexPath:indexPath];
    
//    Get UIImage for current row
    UIImage *photo = self.bestPhotos[indexPath.row];
//    Create UIImageView
    UIImageView *photoView = [[UIImageView alloc] initWithImage:photo];
    photoView.frame = CGRectMake(cellBorder, cellBorder, viewWidth/2 - cellBorder*2, viewWidth/2 - cellBorder*2);
//    Set highlighting background
    cell.backgroundColor = [self.selectedPhotos containsObject:photo] ? [UIColor turquoiseColor] : [UIColor clearColor];
    [cell.contentView addSubview:photoView];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.bestPhotosToLoad == 4) return;
    UIImage *photo = self.bestPhotos[indexPath.row];
    if ([self.selectedPhotos containsObject:photo]){
        [self.selectedPhotos removeObject:photo];
    } else {
        if (self.selectedPhotos.count < 4) {
            [self.selectedPhotos push:photo];
        } else {
            FUIAlertView *maxPhotosAlert = [CommonSettings appStyleAlertViewWithTitle:@"Максимум фотографий"
                                                                         message:@"На данный момент в коллаж можно объединить только 4 фотографии"
                                                                        delegate:nil
                                                               cancelButtonTitle:@"Ок"
                                                                otherButtonTitle:nil];
            [maxPhotosAlert show];
        }
    }
//    Enable button if 4 photos selected
//    P.S. Not quite reactive, but there are problems with arrays KVO...
    self.makeCollageBtn.enabled = self.selectedPhotos.count == 4;
    
    self.chosenLabel.text = [NSString stringWithFormat:@"Выбрано %lu/4", (unsigned long)self.selectedPhotos.count];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [self.selectedPhotos containsObject:photo] ? [UIColor turquoiseColor] : [UIColor clearColor];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//     Get the new view controller using [segue destinationViewController].
//     Pass the selected object to the new view controller.
    CollageViewController *target = [segue destinationViewController];
    [target setCollageImg:self.resultingImage];
}

@end
