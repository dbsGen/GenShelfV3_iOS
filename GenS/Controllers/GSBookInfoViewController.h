//
//  GSBookInfoViewController.h
//  GenS
//
//  Created by mac on 2017/5/17.
//  Copyright © 2017年 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GSBookInfoViewController : UIViewController

@property (nonatomic, copy) void (^closeBlock)();
@property (nonatomic, copy) void (^pushController)(UIViewController *);

- (id)initWithBook:(void*)book library:(void*)library shop:(void*)shop;

@end
