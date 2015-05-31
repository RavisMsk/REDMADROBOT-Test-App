//
//  InstaUser.h
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InstaUser : NSObject

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *fullname;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSURL *avatarUrl;
@property (nonatomic) NSUInteger photos;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
