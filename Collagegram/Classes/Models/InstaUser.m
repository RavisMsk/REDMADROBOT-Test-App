//
//  InstaUser.m
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import "InstaUser.h"

@implementation InstaUser

- (instancetype)initWithDictionary:(NSDictionary *)dict{
    self = [super init];
    if (self){
        self.userId = dict[@"id"];
        self.username = dict[@"username"];
        self.fullname = dict[@"full_name"];
        self.avatarUrl = [NSURL URLWithString:dict[@"profile_picture"]];
        self.photos = [dict[@"counts"][@"media"] unsignedIntegerValue];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"InstaUser(%@, %@, %@, %lu)", self.userId, self.username, self.fullname, self.photos];
}

@end
