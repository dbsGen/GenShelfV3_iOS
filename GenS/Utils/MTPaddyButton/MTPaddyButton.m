//
//  MTElasticityButton.m
//  MTElasticityButton
//
//  Created by zrz on 13-1-9.
//  Copyright (c) 2013年 zrz. All rights reserved.
//

#import "MTPaddyButton.h"
#import "MTPaddyLayer.h"

@implementation MTPaddyButton {
    CGPoint _startP;
    BOOL    _in;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.paddyLayer.elasticityX = 0.3;
        self.paddyLayer.elasticityY = 0.3;
    }
    return self;
}

- (MTPaddyLayer *)paddyLayer
{
    return (id)self.layer;
}

+ (Class)layerClass
{
    return [MTPaddyLayer class];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint p = [touch locationInView:self];
    _startP = p;
    _in = YES;
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint p = [touch locationInView:self];
    CGRect rect = self.bounds;
    if (_in && CGRectContainsPoint(CGRectInset(rect, -50, -50), p)) {
        float y = p.y - rect.size.height / 2, x = p.x - rect.size.width / 2;
        float f1 = atan2f(y, x);
        
        float length = sqrtf(x*x + y*y);
        float persent = length / rect.size.width / 5;
        if (persent > 1) {
            persent = 1;
        }
        [self.paddyLayer rotation:f1 persent:persent];
    }else if (_in){
        _in = NO;
        float y = p.y - rect.size.height / 2, x = p.x - rect.size.width / 2;
        float f1 = atan2f(y, x);
        [self.paddyLayer elastic:MTElasiticityAll rotation:f1];
    }
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (_in) {
        CGPoint p = [touch locationInView:self];
        CGRect rect = self.bounds;
        float y = p.y - rect.size.height / 2, x = p.x - rect.size.width / 2;
        float f1 = atan2f(y, x);
        [self.paddyLayer elastic:MTElasiticityAll rotation:f1];
        _in = NO;
    }
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    if (_in) {
        [self.paddyLayer elastic:MTElasiticityAll];
    }
}

@end
