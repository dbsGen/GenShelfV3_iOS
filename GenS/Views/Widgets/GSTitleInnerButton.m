//
//  GSTitleInnerButton.m
//  GenS
//
//  Created by mac on 2017/6/24.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSTitleInnerButton.h"

@implementation GSTitleInnerButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _triView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tri"]];
        _triView.frame = CGRectMake(frame.size.width + 4, (frame.size.height - 12)/2, 12, 12);
        [self addSubview:_triView];
        
        [self setTitleColor:[UIColor grayColor]
                   forState:UIControlStateHighlighted];
    }
    return self;
}

- (void)updateTriPosition {
    CGRect frame = self.bounds;
    CGSize size = [self.titleLabel sizeThatFits:CGSizeMake(300, 40)];
    _triView.frame = CGRectMake(frame.size.width/2 + size.width/2, (frame.size.height - 10)/2, 12, 12);
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updateTriPosition];
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    [super setTitle:title forState:state];
    [self updateTriPosition];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        _triView.alpha = 0.4;
    }else {
        _triView.alpha = 1;
    }
}

- (void)extend:(BOOL)ex {
    [UIView animateWithDuration:0.3
                     animations:^{
                         if (ex)
                             _triView.transform = CGAffineTransformMakeRotation(M_PI);
                         else
                             _triView.transform = CGAffineTransformIdentity;
                     }];
}

@end
