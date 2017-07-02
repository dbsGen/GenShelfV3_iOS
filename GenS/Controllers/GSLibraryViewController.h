//
//  GSLibraryViewController.h
//  GenS
//
//  Created by mac on 2017/5/16.
//  Copyright © 2017年 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GSLibraryViewController : UIViewController

@property (nonatomic, strong) UITableView *tableView;
+ (void)setReloadCache:(BOOL)reload;

@end
