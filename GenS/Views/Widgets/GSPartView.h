//
//  GSPartView.h
//  GenS
//
//  Created by mac on 2017/5/17.
//  Copyright © 2017年 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GSPartView;

@protocol GSPartDelegate <NSObject>

- (void)partView:(GSPartView *)partView select:(NSInteger)index;

@end

@interface GSPartView : UIView

@property (nonatomic, weak) id<GSPartDelegate> delegate;
@property (nonatomic, assign) NSInteger selected;

- (id)initWithLabels:(NSArray *)labels;

@end
