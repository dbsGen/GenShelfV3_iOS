//
//  GSDownloadManager.h
//  GenS
//
//  Created by mac on 2017/5/18.
//  Copyright © 2017年 gen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DIManager.h"

@interface GSDownloadManager : NSObject

+ (instancetype)defaultManager;

- (void)startItemWithUrl:(NSString *)url block:(void(^)(DIItem *))block;
- (void)bringFirst:(NSString *)url;
- (void)removeItems:(NSArray *)items;

- (void *)collect:(void*)chapter book:(void *)book shop:(void *)shop;

@end
