//
//  Photo.m
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import "Photo.h"

@implementation Photo

- (instancetype)initWithDictionary:(NSDictionary *)dict{
    self = [super init];
    if (self) {
        self.likesCount = [dict[@"likes"][@"count"] unsignedIntegerValue];
        self.lowResPhotoUrl = [NSURL URLWithString:dict[@"images"][@"low_resolution"][@"url"]];
        self.highResPhotoUrl = [NSURL URLWithString:dict[@"images"][@"standard_resolution"][@"url"]];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Photo(%lu, %@)", self.likesCount, self.highResPhotoUrl.absoluteString];
}

@end
