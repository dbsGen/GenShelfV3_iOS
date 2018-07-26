//
//  GSBadgeView.m
//  GenS
//
//  Created by mac on 2017/7/4.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSBadgeView.h"
#import "GlobalsDefine.h"

@implementation GSBadgeView {
    UILabel *_label;
}

#define SIZE 18

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(0, 0, SIZE, SIZE)];
    if (self) {
        self.backgroundColor = RED_COLOR;
        self.layer.cornerRadius = SIZE/2;
        self.clipsToBounds = YES;
        
        _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SIZE, SIZE)];
        [self addSubview:_label];
        _label.textColor = [UIColor whiteColor];
        _label.font = [UIFont systemFontOfSize:12];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)setText:(NSString *)text {
    _label.text = text;
    CGSize size = [_label sizeThatFits:CGSizeMake(999, 999)];
    CGSize sizeToSet = CGSizeMake(MAX(SIZE, size.width), SIZE);
    CGRect bounds = self.frame;
    bounds.size = sizeToSet;
    self.frame = bounds;
}

@end
