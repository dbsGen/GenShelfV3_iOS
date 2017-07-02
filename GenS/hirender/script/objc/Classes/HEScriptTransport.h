//
//  HEScriptTransport.h
//  hirender_iOS
//
//  Created by Gen on 16/10/5.
//  Copyright © 2016年 gen. All rights reserved.
//

#import "HiObject.h"
#import "HECallback.h"

@protocol HEScriptTransport <HiClass>

+ (void)reg:(NSString *)name :(HECallback*)callback;
+ (void)send:(NSString *)name :(id)send;

@end

@interface HEScriptTransport : HiObject <HEScriptTransport>

@end
