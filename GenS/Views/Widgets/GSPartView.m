//
//  GSPartView.m
//  GenS
//
//  Created by mac on 2017/5/17.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSPartView.h"
#import "GlobalsDefine.h"
#import "GTween.h"

@implementation GSPartView {
    NSArray *_buttons;
    UIView *_blueBar;
}

#define BUTTON_SIZE 88

- (id)initWithLabels:(NSArray *)labels {
    self = [super initWithFrame:CGRectMake(0, 0, 480, 40)];
    if (self) {
        NSMutableArray *buttons = [NSMutableArray array];
        for (NSString *label in labels) {
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_SIZE, 40)];
            [button setTitle:label forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:16];
            [button setTitleColor:[UIColor colorWithWhite:0.3 alpha:1]
                         forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithWhite:0.7 alpha:1]
                         forState:UIControlStateHighlighted];
            [button addTarget:self
                       action:@selector(buttonChecked:)
             forControlEvents:UIControlEventTouchUpInside];
            [buttons addObject:button];
            [self addSubview:button];
        }
        _buttons = buttons;
        
        _blueBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, BUTTON_SIZE, 2)];
        _blueBar.backgroundColor = BLUE_COLOR;
        [self addSubview:_blueBar];
        
        _selected = -1;
        self.selected = 0;
    }
    return self;
}

- (void)updateSizes {
    NSInteger count = _buttons.count;
    CGFloat left = (self.bounds.size.width - BUTTON_SIZE * count)/2;
    for (int  i = 0; i < count; ++i) {
        UIButton *button = [_buttons objectAtIndex:i];
        button.frame = CGRectMake(i * BUTTON_SIZE + left, 0, BUTTON_SIZE, self.bounds.size.height);
    }
    _blueBar.frame = CGRectMake(_selected * BUTTON_SIZE + left, 0, BUTTON_SIZE, 2);
}

- (void)setSelected:(NSInteger)selected {
    if (_selected != selected) {
        if (_selected >= 0 && _selected < _buttons.count) [[_buttons objectAtIndex:_selected] setBackgroundColor:[UIColor whiteColor]];
        [[_buttons objectAtIndex:selected] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1]];
        _selected = selected;
        NSInteger count = _buttons.count;
        CGFloat left = (self.bounds.size.width - BUTTON_SIZE * count)/2;
        _blueBar.frame = CGRectMake(_selected * BUTTON_SIZE + left, 0, BUTTON_SIZE, 2);
    }
}

- (void)buttonChecked:(id)button {
    NSInteger idx = [_buttons indexOfObject:button];
    if (idx >= 0 && _selected != idx) {
        NSInteger count = _buttons.count;
        CGFloat left = (self.bounds.size.width - BUTTON_SIZE * count)/2;
        [GTween cancel:_blueBar];
        GTween *tween = [GTween tween:_blueBar
                             duration:0.4
                                 ease:[GEaseCubicOut class]];
        [tween addProperty:[GTweenCGRectProperty property:@"frame"
                                                     from:_blueBar.frame
                                                       to:CGRectMake(idx * BUTTON_SIZE + left, 0, BUTTON_SIZE, 2)]];
        [tween start];
        [[_buttons objectAtIndex:_selected] setBackgroundColor:[UIColor whiteColor]];
        [[_buttons objectAtIndex:idx] setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1]];
        _selected = idx;
        if ([self.delegate respondsToSelector:@selector(partView:select:)])
            [self.delegate partView:self select:_selected];
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updateSizes];
}

@end
