//
//  GSCoverSelectView.m
//  GenS
//
//  Created by mac on 2017/5/22.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSCoverSelectView.h"

@interface GSCoverSelectView() <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation GSCoverSelectView {
    UIControl *_coverView;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _tableView = [[UITableView alloc] initWithFrame:self.bounds];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [self addSubview:_tableView];
        
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 10;
    }
    return self;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.params.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"normal";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellId];
    }
    cell.accessoryType = indexPath.row == self.selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.textLabel.text = [self.params objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(coverSelectView:selected:)]) {
        [self.delegate coverSelectView:self selected:indexPath.row];
    }
}

- (void)show {
    if (_coverView) return;
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    _coverView = [[UIControl alloc] initWithFrame:window.bounds];
    _coverView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    _coverView.alpha = 0;
    [_coverView addTarget:self
                   action:@selector(miss)
         forControlEvents:UIControlEventTouchUpInside];
    [window addSubview:_coverView];
    
    [window addSubview:self];
    CGRect rect = self.frame;
    self.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 0);
    [UIView animateWithDuration:0.3
                     animations:^{
                         _coverView.alpha = 1;
                         self.frame = rect;
                     }];
}

- (void)miss {
    if (!_coverView) return;
    UIControl *cover = _coverView;
    CGRect rect = self.frame;
    [UIView animateWithDuration:0.3
                     animations:^{
                         _coverView.alpha = 0;
                         self.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 0);
                     } completion:^(BOOL finished) {
                         [cover removeFromSuperview];
                         [self removeFromSuperview];
                     }];
    _coverView = nil;
    if ([self.delegate respondsToSelector:@selector(coverSelectViewMiss:)])
        [self.delegate coverSelectViewMiss:self];
}

- (void)setSelected:(NSInteger)selected {
    if (_selected != selected) {
        _selected = selected;
    
        _tableView.contentOffset = CGPointMake(0, 40 * MIN(selected, self.params.count - 4));
    }
}

@end
