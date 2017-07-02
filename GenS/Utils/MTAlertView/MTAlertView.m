//
//  MTAlertView.m
//  SOP2p
//
//  Created by zrz on 12-6-22.
//  Copyright (c) 2012年 Sctab. All rights reserved.
//

#import "MTAlertView.h"
#import <QuartzCore/QuartzCore.h>
#import "GTween.h"
#import "MTButton.h"

@implementation MTAlertView {
    UILabel     *_title;
    UILabel     *_content;
    UIImageView *_imageView;
    UIView      *_maskView;
    NSMutableArray  *_buttons;
}

@synthesize delegate = _delegate;

- (CGRect)autoImage:(UIImage*)image maxRect:(CGRect)rect
{
    CGRect addRect;
    CGSize tSize = image.size;
    if (tSize.height < rect.size.height && tSize.width < rect.size.width) {
        addRect.origin.y = rect.origin.y + (rect.size.height - tSize.height) / 2;
        addRect.origin.x = rect.origin.x + (rect.size.width - tSize.width) / 2;
        addRect.size.width = tSize.width;
        addRect.size.height = tSize.height;
    }else{
        if (tSize.height * rect.size.width / tSize.width > rect.size.height) {
            addRect.size.height = rect.size.height;
            addRect.size.width = tSize.width * rect.size.height / tSize.height;
            addRect.origin.x = rect.origin.x + (rect.size.width - addRect.size.width) / 2;
            addRect.origin.y = rect.origin.y;
        }else {
            addRect.origin.x = rect.origin.x;
            addRect.size.width = rect.size.width;
            addRect.size.height = tSize.height * rect.size.width / tSize.width;
            addRect.origin.y = rect.origin.y + (rect.size.height - addRect.size.height) / 2;
        }
    }
    return addRect;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
//        self.backgroundColor = [UIColor colorWithWhite:0.0f 
//                                                 alpha:0.9f];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:imageView];
    }
    return self;
}

//- (void)setBackgroundColor:(UIColor *)backgroundColor {
//    if (self.backgroundColor != backgroundColor) {
//        [super setBackgroundColor:backgroundColor];
//        self.layer.shadowColor = backgroundColor.CGColor;
//        self.layer.shadowOpacity = 1.0f;
//        self.layer.cornerRadius = 5.0f;
//    }
//}

- (instancetype)initWithTitle:(NSString *)title
                      content:(NSString *)content
                          image:(nullable UIImage *)image
                        buttons:(nullable NSString *)label, ... {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 10;
        
        CGFloat top = 21.0f;
        const CGFloat width = 347.0f;
        const CGFloat margin = 20.0f;
        
        if (title) {
            CGFloat fontSize = 16;
            CGSize size = [title sizeWithFont:[UIFont systemFontOfSize:fontSize]
                              constrainedToSize:CGSizeMake(width, MAXFLOAT)];
            _title = [[UILabel alloc] initWithFrame:(CGRect){margin, top, width - margin * 2, size.height}];
            _title.numberOfLines = 0;
            _title.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
            _title.font = [UIFont systemFontOfSize:fontSize];
            _title.backgroundColor = [UIColor clearColor];
            _title.textAlignment = NSTextAlignmentCenter;
            _title.text = title;
            [self addSubview:_title];
            top += size.height;
        }
        
        if (content) {
            CGFloat fontSize = 17;
            top += 12;
            CGSize size = [content sizeWithFont:[UIFont boldSystemFontOfSize:fontSize]
                              constrainedToSize:CGSizeMake(width, MAXFLOAT)];
            _content = [[UILabel alloc] initWithFrame:(CGRect){margin, top, width - margin * 2, size.height}];
            _content.numberOfLines = 0;
            _content.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
            _content.font = [UIFont boldSystemFontOfSize:fontSize];
            _content.backgroundColor = [UIColor clearColor];
            _content.textAlignment = NSTextAlignmentCenter;
            _content.text = content;
            [self addSubview:_content];
            top += size.height + 18;
        }
        
        if (image) {
            CGRect rect = [self autoImage:image
                                  maxRect:CGRectMake(margin, top, width - margin * 2, width)];
            _imageView = [[UIImageView alloc] initWithFrame:
                          CGRectMake(margin, top, rect.size.width,
                                     rect.size.height)];
            _imageView.image = image;
            [self addSubview:_imageView];
            top += rect.size.height + margin;
        }
        
        int count = 0;
        NSString *str[10];
        if ((str[0] = label)) {
            va_list list;
            va_start(list, label);
            count = 1;
            while ((str[count] = va_arg(list, id))) {
                count++;
            }
            va_end(list);
        }
        
        _buttons = [NSMutableArray array];
        if (count) {
            CGFloat buttonW = (width) / count;
            CGFloat buttonH = 56.0f;
            
            for (int n = 0 ; n < count; n++) {
                MTButton *button = [[MTButton alloc] init];
                button.frame = CGRectMake(buttonW * n, 84, buttonW, buttonH);
                [button setTitle:str[n] forState:UIControlStateNormal];
                button.titleLabel.font = [UIFont boldSystemFontOfSize:17];
                [button setTitleColor:[UIColor colorWithRed:1 green:0.56 blue:0 alpha:1] forState:UIControlStateNormal];
                [button setTitleColor:[UIColor colorWithRed:1 green:0.56 blue:0 alpha:1] forState:UIControlStateHighlighted];
                [button addTarget:self action:@selector(buttonClickedTouchDown:) forControlEvents:UIControlEventTouchDown];
                [button addTarget:self action:@selector(buttonClickedTouchDragExit:) forControlEvents:UIControlEventTouchDragExit];
                [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
                button.tag = n;
                button.isLeft = n % 2 != 0;
                [_buttons addObject:button];
                [self addSubview:button];
            }
            
            top = buttonH + 84;
        }
        
        self.frame = CGRectMake(0, 0, width, top);
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
    }
    return self;
}
                 
- (void)buttonClicked:(UIButton *)button
{
    if ([_delegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
        [_delegate alertView:self clickedButtonAtIndex:button.tag];
    }
    [self miss];
}

- (void)buttonClickedTouchDown:(UIButton *)sender {
    sender.backgroundColor = [UIColor colorWithRed:0.93 green:0.92 blue:0.92 alpha:0.9]; // 238,235,235
}

- (void)buttonClickedTouchDragExit:(UIButton *)sender {
    sender.backgroundColor = [UIColor whiteColor];
}

- (void)setFrame:(CGRect)frame {
    
    CGFloat top = 21.0f;
    float width = frame.size.width * 0.8;
    const CGFloat margin = frame.size.width * 0.1;

    if (_title) {
        CGSize size = [_title.text sizeWithFont:_title.font
                              constrainedToSize:CGSizeMake(width, MAXFLOAT)];
        _title.frame = (CGRect){margin, top, width, size.height};
        top += size.height;
    }
    
    if (_content) {
        top += 12;
        CGSize size = [_content.text sizeWithFont:_content.font
                          constrainedToSize:CGSizeMake(width, MAXFLOAT)];
        _content.frame = (CGRect){margin, top, width, size.height};
        top += size.height + 18;
    }
    
    CGFloat bh = 56.0f;
    if (_buttons.count > 0) {
        CGFloat bw = frame.size.width / _buttons.count;
        [_buttons enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            MTButton *button = obj;
            button.frame = CGRectMake(bw * idx, top, bw, bh);
        }];
    }
    
    frame.size.height = top + bh;
    [super setFrame:frame];
}

- (void)show
{
//    void(^imageBlock)(UIImage *image) = ^(UIImage *image){
//
//    };
//    [[MTImageCenter defaultCenter] getImageFromLayer:self.layer
//                                          whithBlock:imageBlock];
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [self showInView:window];
}

- (void)showInView:(UIView*)view {
    _maskView = [[UIView alloc] initWithFrame:view.bounds];
    _maskView.backgroundColor = [UIColor lightGrayColor];
    _maskView.alpha = 0.4;
    _maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:_maskView];
    
    CGSize oldSize = self.bounds.size;
    self.frame = CGRectMake(0, 0, MAX(view.frame.size.width * 6 / 11, 260), oldSize.height);
    self.center = view.center;
    [view insertSubview:self aboveSubview:_maskView];
    
    self.transform = CGAffineTransformMakeScale(0, 0);
    GTween *tween = [GTween tween:self
                         duration:0.3
                             ease:[GEaseBackOut class]];
    [tween addProperty:[GTweenCGAffineTransformProperty  property:@"transform"
                                                             from:self.transform
                                                               to:CGAffineTransformIdentity]];
    [tween start];
    
    /*
    CGSize oldSize = self.bounds.size;
    self.frame = CGRectMake(self.center.x, self.center.y, 0, 0);
    self.alpha = 0;
    
    [UIView animateWithDuration:0.33
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:1
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.frame = CGRectMake(self.center.x, self.center.y, oldSize.width, oldSize.height);
                         self.alpha = 1;
                     } completion:^(BOOL finished) {
                          
                     }];
     */
}

- (void)miss {
    [UIView transitionWithView:self
                      duration:0.25
                       options:UIViewAnimationOptionCurveEaseOut
                    animations:^{
                        self.transform = CGAffineTransformMakeScale(0, 0);
                        _maskView.alpha = 0;
                    } completion:nil];
    [self performSelector:@selector(removeFromSuperview)
               withObject:nil
               afterDelay:0.25];
    [_maskView performSelector:@selector(removeFromSuperview)
                    withObject:nil
                    afterDelay:0.25];
}

@end
