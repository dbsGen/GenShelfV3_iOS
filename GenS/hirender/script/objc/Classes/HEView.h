//
//  HEView.h
//  hirender_iOS
//
//  Created by gen on 16/11/2016.
//  Copyright © 2016 gen. All rights reserved.
//

#import "HEObject.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol HEView <HEObject>

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) CGFloat corner;
@property (nonatomic, assign) GLKVector4 borderColor;
@property (nonatomic, assign) NSInteger depth;
@property (nonatomic, assign) CGFloat alpha;

@end

@interface HEView : HEObject <HEView>

@end
