//
//  HEObject.h
//  hirender_iOS
//
//  Created by Gen on 16/10/17.
//  Copyright © 2016年 gen. All rights reserved.
//

#import "HiObject.h"
#import <GLKit/GLKit.h>

@class HEObject;

@protocol HEObject <HiClass>

@property (nonatomic, assign) id material;
@property (nonatomic, assign) id mesh;
@property (nonatomic, assign) NSString *name;
@property (nonatomic, assign) NSInteger mask;
@property (nonatomic, assign) NSInteger hitMask;
@property (nonatomic, assign) BOOL collision;
@property (nonatomic, assign) id collider;
@property (nonatomic, assign) BOOL enable;

- (void)sendMessage:(NSString*)key :(NSInteger)direction :(NSArray *)vars;
- (void)rotate:(CGFloat)radis :(GLKVector3)rotate;
- (void)translate:(GLKVector3)translate;
- (void)scale:(GLKVector3)scale;
- (GLKMatrix4)getGlobalPose;
- (id)getParent;
- (void)add:(HEObject*)obj;
- (void)remove:(HEObject*)obj;
- (BOOL)isFinalEnable;

@end

@interface HEObject : HiObject <HEObject>

@end
