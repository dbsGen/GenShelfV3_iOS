//
//  HERenderer.h
//  hirender_iOS
//
//  Created by Gen on 16/9/21.
//  Copyright © 2016年 gen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "../HiObject.h"

@class HEController;
@class HRRenderer;

@protocol HERendererDelegate <NSObject>

@required
- (void)requireRender;

@end

@protocol HRRenderer <HiClass>

@property (nonatomic, assign) id currentCamera;
@property (nonatomic, assign) HEController *mainController;
@property (nonatomic, assign) GLKVector4 clearColor;
@property (nonatomic, assign) CGSize size;

+ (HRRenderer*)sharedInstance;
- (void)render;
- (void)dirty;
- (id)getUICamera;
- (id)getCamera:(NSInteger)index;
- (void)touchBegin:(id)point;
- (void)touchMove:(id)point;
- (void)touchEnd:(id)point;
- (void)touchCancel:(id)point;
- (void)add:(id)object;
- (void)remove:(id)object;
- (void)attach:(id)plugin;
- (void)disattach:(id)plugin;

@end

@interface HERenderer : HiObject <HRRenderer>

@property (nonatomic, assign) id<HERendererDelegate> delegate;

- (void)_requireRender;

@end
