//
//  GSDragView.h
//  GenS
//
//  Created by gen on 23/06/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GSDragView;

@interface GSDragViewCell : UIScrollView

@property (nonatomic, strong) UIImage *image;

@end

@protocol GSDragViewDelegate <NSObject>

- (NSInteger)dragViewCellCount:(GSDragView *)dragView;
- (GSDragViewCell *)dragView:(GSDragView *)dragView atIndex:(NSInteger)index;
- (void)dragView:(GSDragView *)dragView page:(NSInteger)index;

- (void)dragView:(GSDragView *)dragView chapter:(BOOL)next;

@end

@interface GSDragView : UIView

@property (nonatomic, weak) id<GSDragViewDelegate> delegate;
@property (nonatomic, assign) NSInteger maxLimit;
@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, readonly) UIScrollView *scrollView;

- (GSDragViewCell *)dequeueCell;
- (void)reloadData;
- (void)reloadCount;

- (void)setPageIndex:(NSInteger)pageIndex animate:(BOOL)animate;

- (GSDragViewCell *)cellAtIndex:(NSInteger)index;

@end
