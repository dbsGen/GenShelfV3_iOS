//
//  ObjcUtils.h
//  hirender_iOS
//
//  Created by Gen on 16/9/23.
//  Copyright © 2016年 gen. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <core/Variant.h>

using namespace hicore;

@interface ObjcUtils : NSObject

typedef void(^ObjcObjectCallback)(void *);
+ (void)objectFromVariant:(const Variant*)var blcok:(ObjcObjectCallback)callback;
+ (Variant)makeVariant:(id)obj;
+ (void)makeArgs:(Variant*)res params:(NSArray*)params;
+ (Variant)apply:(id)object :(SEL)sel :(const Variant**)params :(int)count;

@end
