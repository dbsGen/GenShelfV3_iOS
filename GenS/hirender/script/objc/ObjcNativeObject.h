//
//  ObjcNativeObject.hpp
//  hirender_iOS
//
//  Created by gen on 16/9/17.
//  Copyright © 2016年 gen. All rights reserved.
//

#ifdef __OBJC__
#ifndef ObjcNativeObject_hpp
#define ObjcNativeObject_hpp

#include <core/script/NativeObject.h>
#import <Foundation/Foundation.h>
#include "../script_define.h"

using namespace hicore;

namespace hiscript {
    CLASS_BEGIN_N(ObjcNativeObject, NativeObject)
    
public:
    
    _FORCE_INLINE_ virtual void setNative(void *native) {
        [((id)getNative()) release];
        NativeObject::setNative(native);
        [((id)native) retain];
    }
    
    _FORCE_INLINE_ ObjcNativeObject(){}
    _FORCE_INLINE_ ObjcNativeObject(void *native) : NativeObject(native) {
        [((id)native) retain];
    }
    _FORCE_INLINE_ ~ObjcNativeObject() {
        [((id)getNative()) release];
    }
    
    CLASS_END
}

#endif /* ObjcNativeObject_hpp */
#endif
