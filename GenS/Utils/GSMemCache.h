//
//  GSMemCache.h
//  GenS
//
//  Created by mac on 2017/6/24.
//  Copyright © 2017年 gen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GSMemCache : NSObject

- (void)loadImage:(NSString *)path block:(void(^)(NSString *path, UIImage *))block;

@end
