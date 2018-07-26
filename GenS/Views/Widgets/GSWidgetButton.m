//
//  GSWidgetButton.m
//  GenS
//
//  Created by mac on 2017/9/3.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSWidgetButton.h"
#import "GlobalsDefine.h"

@implementation GSWidgetButton {
    UIView *_backgroundView;
    UIImageView *_iconView;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height);
        _backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
        _backgroundView.clipsToBounds = YES;
        _backgroundView.layer.cornerRadius = size/2;
        _backgroundView.userInteractionEnabled = NO;
        _backgroundView.backgroundColor = BLUE_COLOR;
        [self addSubview:_backgroundView];
        
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        _iconView.userInteractionEnabled = NO;
        [self addSubview:_iconView];
        
        [self updateFrame:frame];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updateFrame:frame];
}

- (void)updateFrame:(CGRect)frame {
    CGFloat f = MIN(frame.size.width, frame.size.height);
    _backgroundView.frame = CGRectMake(0, 0, f, f);
    _backgroundView.center = CGPointMake(frame.size.width/2, frame.size.height/2);
    _iconView.center = CGPointMake(frame.size.width/2, frame.size.height/2);
}

- (void)setIconImage:(UIImage *)iconImage {
    _iconImage = iconImage;
    _iconView.image = iconImage;
}

@end
