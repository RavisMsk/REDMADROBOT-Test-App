//
//  BestPhotosCrawler.h
//  Collagegram
//
//  Created by Nikita Anisimov on 30/05/15.
//  Copyright (c) 2015 Nikita Anisimov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BestPhotosCrawlingProgress)(NSUInteger photosCrawled);
typedef void(^BestPhotosHandler)(NSArray *bestPhotos);
typedef void(^BestPhotosCrawlerError)(NSError *error);

@interface BestPhotosCrawler : NSObject

+ (instancetype)crawlerForBestPhotosForUserId:(NSString *)userId
                               numberOfPhotos:(NSUInteger)number
                            bestPhotosHandler:(BestPhotosHandler)handler
                              progressHandler:(BestPhotosCrawlingProgress)progressHandler
                                 errorHandler:(BestPhotosCrawlerError)errorHandler;

+ (instancetype)crawlerForBestPhotosForUserId:(NSString *)userId
                            bestPhotosHandler:(BestPhotosHandler)handler
                                 errorHandler:(BestPhotosCrawlerError)errorHandler;


- (void)crawl;
- (void)cancel;

@end
