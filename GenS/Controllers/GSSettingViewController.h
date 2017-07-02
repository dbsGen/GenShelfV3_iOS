//
//  GSSettingViewController.h
//  GenS
//
//  Created by mac on 2017/5/16.
//  Copyright © 2017年 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GSSettingViewController : UIViewController

@property (nonatomic, copy) void(^closeCoverBlock)();
- (id)initWithShop:(void*)shop;

@end
