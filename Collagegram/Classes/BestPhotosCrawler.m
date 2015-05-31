//
//  BestPhotosCrawler.m
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import "BestPhotosCrawler.h"

#import <ObjectiveSugar/ObjectiveSugar.h>

#import "UserPhotosIterator.h"
#import "Photo.h"

@interface BestPhotosCrawler ()

@property (nonatomic, strong) UserPhotosIterator *iterator;
@property (nonatomic, strong) NSMutableArray *bestPhotos;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic) BOOL isCancelled;

@end

@implementation BestPhotosCrawler

- (instancetype)initWithUserId:(NSString *)userId {
    self = [super init];
    if (self) {
        self.bestPhotos = [NSMutableArray new];
        self.isCancelled = NO;
        self.userId = userId;
    }
    return self;
}

- (void)crawl{
    [self.iterator fetchNext];
}

- (void)cancel {
    self.isCancelled = YES;
}

+ (instancetype)crawlerForBestPhotosForUserId:(NSString *)userId
                            bestPhotosHandler:(BestPhotosHandler)handler
                                 errorHandler:(BestPhotosCrawlerError)errorHandler {
    return [self crawlerForBestPhotosForUserId:userId
                                numberOfPhotos:4
                             bestPhotosHandler:handler
                               progressHandler:nil
                                  errorHandler:errorHandler];
}

+ (instancetype)crawlerForBestPhotosForUserId:(NSString *)userId
                               numberOfPhotos:(NSUInteger)number
                            bestPhotosHandler:(BestPhotosHandler)handler
                              progressHandler:(BestPhotosCrawlingProgress)progressHandler
                                 errorHandler:(BestPhotosCrawlerError)errorHandler {
    if (!handler)
        @throw [NSException exceptionWithName:@"No photos handler"
                                       reason:@"Crawler requires final handler for submitting best photos"
                                     userInfo:nil];
    
    BestPhotosCrawler *crawler = [[BestPhotosCrawler alloc] initWithUserId:userId];
    
    void (^finishHandler)() = ^void() {
//        Sort accumulated most liked photos of all chunks
//        Then slice and call handler
        handler([[crawler.bestPhotos sortedArrayUsingDescriptors:@[
                                                                   [[NSSortDescriptor alloc] initWithKey:@"likesCount"  ascending:NO]
                                                                   ]] subarrayWithRange:NSMakeRange(0, MIN(crawler.bestPhotos.count, number))]);
    };
    
    void (^nextHandler)(NSArray *) = ^void(NSArray *photos) {
//        Sort photos chunk by likes
        NSArray *partlyBest = [photos sortedArrayUsingDescriptors:@[
                                                                    [[NSSortDescriptor alloc] initWithKey:@"likes.count"  ascending:NO]
                                                                    ]];
//        Get N most liked photos in this chunk
        partlyBest = [partlyBest subarrayWithRange:NSMakeRange(0, MIN(partlyBest.count, number))];
//        Map to Photo object
        partlyBest = [partlyBest map:^(NSDictionary *photoObj){
            return [[Photo alloc] initWithDictionary: photoObj];
        }];
//        Append to accumulator
        [crawler.bestPhotos addObjectsFromArray:partlyBest];
//        Now sort and slice down accumulator
        [crawler.bestPhotos sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"likesCount"  ascending:NO]]];
        if (crawler.bestPhotos.count > number)
            [crawler.bestPhotos removeObjectsInRange:NSMakeRange(number, crawler.bestPhotos.count - number)];
//        If crawler shouldn't stop
        if (!crawler.isCancelled) {
//            Fetch more
            [crawler.iterator fetchNext];
//            If progress handler is specified than send progress
            if (progressHandler)
                progressHandler(crawler.iterator.photosFetched);
        } else {
//            Else call finish handler manually with curretly fetched photos
            finishHandler();
        }
    };
    
    crawler.iterator = [UserPhotosIterator iteratorForUserId:userId
                                         nextHandler:nextHandler
                                       finishHandler:finishHandler
                                        errorHandler:^(NSError *error){
                                            errorHandler(error);
                                        }];
    
    return crawler;
}

@end
