//
//  GSShopInfoViewController.h
//  GenS
//
//  Created by gen on 16/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GSShopInfoViewController : UIViewController

@property (nonatomic, copy) void (^closeBlock)();
@property (nonatomic, copy) void (^settingBlock)(void *);

- (id)initWithLocalShop:(void*)localShop onlineShop:(void*)onlineShop;

@end
