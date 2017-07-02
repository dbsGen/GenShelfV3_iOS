//
//  HECallback.h
//  hirender_iOS
//
//  Created by Gen on 16/9/25.
//  Copyright © 2016年 gen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../HiObject.h"

@class HECallback;

@protocol HECallbackDelegate <NSObject>

- (id)action:(HECallback*)callback;

@end

@protocol HECallback <HiClass>

@end

typedef id(^HECallbackBlock)(NSArray *params);

@interface HECallback : HiObject <HECallback>

@property (nonatomic, copy) HECallbackBlock block;
@property (nonatomic, retain) id userdata;
@property (nonatomic, assign) id<HECallbackDelegate> delegate;

- (id)_invoke:(NSArray*)params;

@end
