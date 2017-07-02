//
//  HEiOSPlatform.h
//  hirender_iOS
//
//  Created by Gen on 16/9/25.
//  Copyright © 2016年 gen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../HiObject.h"
#import "HECallback.h"

@class HEiOSPlatform;

@protocol HEiOSPlatform <HiClass>

+ (void)reg:(HEiOSPlatform*)platform;
+ (HEiOSPlatform*)sharedPlatform;
- (void)startInput:(NSString*)text :(NSString*)placeholder :(HECallback*)callback;
- (void)endInput;

- (NSString*)persistencePath;

- (void)setTestCallback:(HECallback*)callback;

@end

@interface HEiOSPlatform : HiObject <HEiOSPlatform>

@property (nonatomic, retain) HECallback* callback;

- (NSString*)_persistencePath;
- (void)_startInput:(NSString*)text :(NSString*)placeholder :(HECallback*)callback;
- (void)_endInput;

@end
