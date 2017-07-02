//
//  HEController.h
//  hirender_iOS
//
//  Created by Gen on 16/10/4.
//  Copyright © 2016年 gen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../HiObject.h"
#import "HERenderer.h"
#import "HEObject.h"

@class HEController;
@class HENavigationController;

@protocol HEController <HiClass>

- (HEController*)getMainObject;
- (HERenderer*)getRenderer;
- (HENavigationController*)getNav;

@end

@interface HEController : HiObject <HEController>

- (void)_onLoad:(HEObject*)main;
- (void)_onUnload:(HEObject*)main;

- (void)_onAttach;
- (void)_onDisattach;

//- (long)_appearDuring;
//- (long)_disappearDuring;

//- (void)_appearProcess:(float)percent;
//- (void)_disappearProcess:(float)percent;

- (void)_willAppear;
- (void)_willDisappear;
- (void)_afterAppear;
- (void)_afterDisappear;



@end
