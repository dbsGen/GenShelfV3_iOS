//
//  GSLocalBookInfoViewController.h
//  GenS
//
//  Created by mac on 2017/5/20.
//  Copyright © 2017年 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GSLocalBookInfoViewController : UIViewController


@property (nonatomic, copy) void (^closeBlock)();
@property (nonatomic, copy) void (^pushController)(UIViewController *);
@property (nonatomic, copy) void (^allRemoved)();

- (id)initWithBook:(void*)book;

@end
