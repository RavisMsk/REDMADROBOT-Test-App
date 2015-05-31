//
//  UserPhotosIterator.m
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import "UserPhotosIterator.h"

#import <AFNetworking/AFNetworking.h>
#import <ObjectiveSugar/ObjectiveSugar.h>

#import "CommonSettings.h"

@interface UserPhotosIterator ()

//Public read-only
@property (nonatomic, readwrite) NSUInteger photosFetched;
@property (nonatomic, readwrite) BOOL finished;
@property (nonatomic, readwrite, strong) NSString *userId;

//Private
@property (nonatomic, strong) UserPhotosNextHandler nextHandler;
@property (nonatomic, strong) UserPhotosFinishedHandler finishHandler;
@property (nonatomic, strong) UserPhotosErrorHandler errorHandler;
@property (nonatomic, strong) NSString *nextMaxId;

@end

@implementation UserPhotosIterator

#pragma mark - Private



#pragma mark - Lifecycle

+ (instancetype)iteratorForUserId:(NSString *)userId
                      nextHandler:(UserPhotosNextHandler)nextHandler
                    finishHandler:(UserPhotosFinishedHandler)finishHandler
                     errorHandler:(UserPhotosErrorHandler)errorHandler{
    UserPhotosIterator *iterator = [UserPhotosIterator new];
    iterator.nextHandler = nextHandler;
    iterator.finishHandler = finishHandler;
    iterator.errorHandler = errorHandler;
    iterator.userId = userId;
    iterator.photosFetched = 0;
    iterator.nextMaxId = nil;
    iterator.finished = NO;
    return iterator;
}

#pragma mark - Public

- (void)fetchNext {
    if (self.finished) return;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSString *queryUrl = [NSString stringWithFormat:@"https://api.instagram.com/v1/users/%@/media/recent", self.userId];
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionaryWithDictionary:@{
                                  @"client_id": CollagegramAppClientId
                                  }];
    if (self.nextMaxId)
        [queryParams setObject:self.nextMaxId
                        forKey:@"max_id"];
    
    [manager GET:queryUrl
      parameters:queryParams
         success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
             if ([responseObject[@"pagination"] hasKey:@"next_max_id"]) {
                 self.nextMaxId = responseObject[@"pagination"][@"next_max_id"];
                 self.photosFetched += [(NSArray*)responseObject[@"data"] count];
                 self.nextHandler(responseObject[@"data"]);
             } else {
                 self.nextMaxId = nil;
                 self.finished = YES;
                 self.nextHandler(responseObject[@"data"]);
                 self.finishHandler();
             }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             self.errorHandler(error);
         }];
}

@end
