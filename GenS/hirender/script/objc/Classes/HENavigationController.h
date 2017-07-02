//
//  HENavigationController.h
//  hirender_iOS
//
//  Created by Gen on 16/10/5.
//  Copyright © 2016年 gen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../HiObject.h"

@class HEController;

@protocol HENavigationController <HiClass>

- (HEController*)getCurrentController;
- (void)push:(HEController*)contorller :(BOOL)animated;
- (HEController*)pop:(BOOL)animated;

@end

@interface HENavigationController : HiObject <HENavigationController>

@end
