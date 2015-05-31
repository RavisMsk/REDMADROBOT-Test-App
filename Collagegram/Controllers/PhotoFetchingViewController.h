//
//  PhotoFetchingViewController.h
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InstaUser;

@interface PhotoFetchingViewController : UIViewController

@property (nonatomic, strong) InstaUser *user;
@property (nonatomic) NSUInteger bestPhotosToLoad;

@end
