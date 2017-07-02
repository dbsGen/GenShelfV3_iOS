//
//  MTElasticityLayer.h
//  SOP2p
//
//  Created by zrz on 12-5-31.
//  Copyright (c) 2012年 zrz. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

typedef enum {
    MTElasiticityVertical   = 0x01,
    MTElasiticityHorizontal = 0x02,
    MTElasiticityAll        = 0x03
} MTElasiticityKey;

@interface MTPaddyLayer : CALayer {
}

@property (assign)  float   elasticityX,
                            elasticityY;

- (void)elastic:(MTElasiticityKey)key;
- (void)elastic:(MTElasiticityKey)key rotation:(float)angle;
- (void)rotation:(float)angle persent:(float)persent;

@end
