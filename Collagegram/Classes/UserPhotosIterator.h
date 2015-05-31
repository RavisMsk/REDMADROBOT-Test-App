//
//  UserPhotosIterator.h
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^UserPhotosNextHandler)(NSArray *photos);
typedef void(^UserPhotosFinishedHandler)();
typedef void(^UserPhotosErrorHandler)(NSError *error);

@interface UserPhotosIterator : NSObject

@property (nonatomic, readonly) NSUInteger photosFetched;
@property (nonatomic, readonly) BOOL finished;
@property (nonatomic, readonly) NSString *userId;

+ (instancetype)iteratorForUserId:(NSString *)userId
                      nextHandler:(UserPhotosNextHandler)nextHandler
                    finishHandler:(UserPhotosFinishedHandler)finishHandler
                     errorHandler:(UserPhotosErrorHandler)errorHandler;

- (void)fetchNext;

@end
