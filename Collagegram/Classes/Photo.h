//
//  Photo.h
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Photo : NSObject

@property (nonatomic, strong) NSURL *lowResPhotoUrl;
@property (nonatomic, strong) NSURL *highResPhotoUrl;
@property (nonatomic) NSUInteger likesCount;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
