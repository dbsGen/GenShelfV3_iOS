//
//  GSLoadingView.m
//  GenS
//
//  Created by gen on 18/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import "GSLoadingView.h"
#import "GTween.h"
#import "GlobalsDefine.h"

@interface GSLoadingView ()


@end

@implementation GSLoadingView {
    UIImageView *_imageView;
    GTweenChain *_tweenChain;
    UILabel *_textLabel;
    UIButton *_button;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _display = YES;
        _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"no_image"]];
        _imageView.frame = CGRectMake(0, 0, 160, 160);
        _imageView.center = CGPointMake(frame.size.width/2, frame.size.height/2);
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:_imageView];
        
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake((160 - frame.size.width) / 2, 160,
                                                               frame.size.width, 40)];
        _textLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.text = @"test";
        _textLabel.hidden = YES;
        _textLabel.font = [UIFont systemFontOfSize:16];
        [_imageView addSubview:_textLabel];
        
        _button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 140, 40)];
        [_button setTitle:@"Button"
                 forState:UIControlStateNormal];
        [_button setTitleColor:BLUE_COLOR
                      forState:UIControlStateNormal];
        [_button setTitleColor:[BLUE_COLOR colorWithAlphaComponent:0.6]
                      forState:UIControlStateHighlighted];
        _button.center = CGPointMake(frame.size.width/2, frame.size.height/2 + 120);
        _button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        _button.hidden = YES;
        [self addSubview:_button];
        
        self.backgroundColor = [UIColor whiteColor];
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (UIButton *)button {
    return _button;
}

- (void)start {
    if (_tweenChain) return;
    _display = YES;
    self.hidden = NO;
    _imageView.image = [UIImage imageNamed:@"no_image"];
    _tweenChain = [GTweenChain tweenChain];
    GTween *tween = [GTween tween:_imageView
                         duration:0.1
                             ease:[GEaseCubicInOut class]];
    CGAffineTransform t1 = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-5 * M_PI / 180), -5, 0);
    CGAffineTransform t2 = CGAffineTransformTranslate(CGAffineTransformMakeRotation(5 * M_PI / 180), 5, 0);
    [tween addProperty:[GTweenCGAffineTransformProperty property:@"transform"
                                                            from:t1
                                                              to:t2]];
    [_tweenChain addTween:tween];
    tween = [GTween tween:_imageView
                         duration:0.1
                             ease:[GEaseCubicInOut class]];
    [tween addProperty:[GTweenCGAffineTransformProperty property:@"transform"
                                                            from:t2
                                                              to:t1]];
    [_tweenChain addTween:tween];
    
    _tweenChain.isLoop = YES;
    [_tweenChain start];
    _textLabel.hidden = YES;
    _button.hidden = YES;
}

- (void)stop {
    [_tweenChain stop];
    _tweenChain = nil;
}

- (void)failed {
    _imageView.image = [UIImage imageNamed:@"failed"];
    if (_tweenChain) {
         [_tweenChain stop];
        _tweenChain = nil;
    }
}

- (void)miss {
    if (_display) {
        _display = NO;
        [self stop];
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.alpha = 0;
                         } completion:^(BOOL finished) {
                             self.hidden = YES;
                         }];
    }
}

- (void)message:(NSString *)label button:(NSString *)button {
    _textLabel.hidden = NO;
    _button.hidden = NO;
    _textLabel.text = label;
    [_button setTitle:button
             forState:UIControlStateNormal];
}

@end
