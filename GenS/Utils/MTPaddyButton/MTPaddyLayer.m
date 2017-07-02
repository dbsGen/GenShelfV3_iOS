//
//  MTElasticityLayer.m
//  SOP2p
//
//  Created by zrz on 12-5-31.
//  Copyright (c) 2012年 zrz. All rights reserved.
//

#import "MTPaddyLayer.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#define kDuration   0.25

NS_INLINE CATransform3D CATransform3DMakeRotationScale(CGFloat angle,CGFloat sx, CGFloat sy,
                                                       CGFloat sz)
{
    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DRotate(transform, angle, 0, 0, 1);
    transform = CATransform3DScale(transform, sx, sy, sz);
    transform = CATransform3DRotate(transform, -angle, 0, 0, 1);
    return transform;
}

@implementation MTPaddyLayer

@synthesize elasticityX = _elasticityX, elasticityY = _elasticityY;

- (id)init
{
    self = [super init];
    if (self) {
        self.elasticityX = 0.1;
        self.elasticityY = 0.1;
    }
    return self;
}

- (void)elastic:(MTElasiticityKey)key
{
    [self elastic:key rotation:0];
}

- (void)elastic:(MTElasiticityKey)key rotation:(float)angle
{
    float w , h;
    if (key & MTElasiticityHorizontal) {
        w = 1 + _elasticityX;
    }else w = 1;
    if (key & MTElasiticityVertical) {
        h = 1 + _elasticityY;
    }else h = 1;
    
    CABasicAnimation *baseAnimation = [CABasicAnimation animationWithKeyPath:@"anchorPoint"];
    baseAnimation.fromValue = [NSValue valueWithCGPoint:self.anchorPoint];
    baseAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)];
    baseAnimation.duration = kDuration / 4;
    self.anchorPoint = CGPointMake(0.5, 0.5);
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.values = [NSArray arrayWithObjects:
                        [NSValue valueWithCATransform3D:self.transform],
                        [NSValue valueWithCATransform3D:CATransform3DMakeRotationScale(angle,w, 2-h, 1)],
                        [NSValue valueWithCATransform3D:CATransform3DMakeRotationScale(angle,1-(w-1)*0.5, 1+(h-1)*0.5, 1)],
                        [NSValue valueWithCATransform3D:CATransform3DMakeRotationScale(angle,1+(w-1)*0.25, 1-(h-1)*0.25, 1)],
                        [NSValue valueWithCATransform3D:CATransform3DMakeRotationScale(angle,1, 1, 1)], nil];
    animation.keyTimes = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:0],
                          [NSNumber numberWithFloat:0.3],
                          [NSNumber numberWithFloat:0.6],
                          [NSNumber numberWithFloat:0.9],
                          [NSNumber numberWithFloat:1], nil];
    self.transform = CATransform3DIdentity;
    animation.timingFunctions = [NSArray arrayWithObjects:
                                 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut],
                                 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                 [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], nil];
    animation.duration = kDuration;
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = [NSArray arrayWithObjects:animation,baseAnimation, nil];
    group.duration = kDuration;
    [self addAnimation:group
                forKey:@""];
}

- (void)rotation:(float)angle persent:(float)persent
{
    float x = cosf(angle) * persent / 2, y = sinf(angle) * persent / 2;
    self.anchorPoint = CGPointMake(0.5 - x, 0.5 - y);
    self.transform = CATransform3DMakeRotationScale(angle, 1 +persent, 1, 1);
}

@end
