//
//  HiObject.h
//  hirender_iOS
//
//  Created by gen on 16/9/17.
//  Copyright © 2016年 gen. All rights reserved.
//

#ifdef __OBJC__
#import <Foundation/Foundation.h>

@protocol HiClass <NSObject>

@required
+ (NSString *)nativeClassName;

@end

@class HiClass;

@interface HiObject : NSObject 

@property (nonatomic, readonly) void *scriptInstance;
@property (nonatomic, readonly) HiClass *nClass;

- (instancetype)initWithClass:(HiClass*)cls;
- (void)initLinker;
- (void)call:(NSString *)name args:(NSArray *)args returnBlock:(void(^)(void*))returnBlock;

@end

@interface HiClass : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) Class instanceClass;
@property (nonatomic, readonly) void *scriptClass;

- (void)call:(NSString *)name args:(NSArray *)args returnBlock:(void(^)(void*))returnBlock;

@end

@interface HiEngine : NSObject

+ (id)getInstance;

- (void)reg:(Class)cls;
- (HiClass *)clazz:(NSString *)name;
+ (HiClass *)clazz:(NSString *)name;

@end

@interface HiEngine (Register)

+ (void)registerClasses;

@end

#endif