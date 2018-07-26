//
//  GSWebViewController.h
//  GenS
//
//  Created by mac on 2017/7/25.
//  Copyright © 2017年 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GSWebViewController : UIViewController

@property (nonatomic, strong) NSURL *url;
- (void)setCallback:(void*)callback;

@end
