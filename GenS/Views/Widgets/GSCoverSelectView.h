//
//  GSCoverSelectView.h
//  GenS
//
//  Created by mac on 2017/5/22.
//  Copyright © 2017年 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GSCoverSelectView;

@protocol GSCoverSelectViewDelegate <NSObject>

- (void)coverSelectView:(GSCoverSelectView *)view selected:(NSInteger)index;
- (void)coverSelectViewMiss:(GSCoverSelectView *)view;

@end

@interface GSCoverSelectView : UIView

@property (nonatomic, strong) NSArray *params;
@property (nonatomic, assign) NSInteger selected;
@property (nonatomic, weak) id<GSCoverSelectViewDelegate> delegate;

- (void)show;
- (void)miss;

@end
