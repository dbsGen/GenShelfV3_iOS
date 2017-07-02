//
//  GSChapterCell.m
//  GenS
//
//  Created by mac on 2017/5/20.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSChapterCell.h"
#import "GlobalsDefine.h"

@implementation GSChapterCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundView.layer.borderWidth = 1;
        self.backgroundView.layer.cornerRadius = 5;
        self.backgroundView.clipsToBounds = YES;
        
        _titleLabel = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [self.contentView addSubview:_titleLabel];
        
        [self setColor:GREEN_COLOR];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        _titleLabel.textColor = [UIColor whiteColor];
        self.backgroundView.backgroundColor = _color;
    }else {
        _titleLabel.textColor = _color;
        self.backgroundView.backgroundColor = [UIColor whiteColor];
    }
}

- (void)setColor:(UIColor *)color {
    _color = color;
    _titleLabel.textColor = color;
    self.backgroundView.layer.borderColor = color.CGColor;
}

@end
