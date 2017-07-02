//
//  MTButton.m
//  AHARSDK
//
//  Created by JT Ma on 22/12/2016.
//  Copyright © 2016 JT Ma. All rights reserved.
//

#import "MTButton.h"

@implementation MTButton

@synthesize isLeft = _isLeft;

- (void)drawRect:(CGRect)rect {
    if (!_isLeft) {
        [self drawLineFrom:CGPointMake(self.bounds.size.width, 0) to:CGPointMake(self.bounds.size.width, self.bounds.size.height)];
    }
    [self drawLineFrom:CGPointMake(0, 0) to:CGPointMake(self.bounds.size.width, 0)];
}

- (void)drawLineFrom:(CGPoint)startPoint to:(CGPoint)endPoint {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGFloat greyColor[4] = {0.6, 0.6, 0.6, 1};
    CGContextSetStrokeColor(context, greyColor);
    CGContextStrokePath(context);
}



@end
