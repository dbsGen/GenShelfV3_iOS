//
//  ObjcInstance.h
//  hirender_iOS
//
//  Created by gen on 16/9/17.
//  Copyright © 2016年 gen. All rights reserved.
//

#ifdef __OBJC__
#ifndef VOIPPROJECT_OBJC_INSTANCE_H
#define VOIPPROJECT_OBJC_INSTANCE_H

#include <core/script/ScriptInstance.h>
#include "../script_define.h"

using namespace hicore;

namespace hiscript {
    CLASS_BEGIN_N(ObjcInstance, ScriptInstance)
        id object;
        
    public:
        virtual Variant apply(const StringName &name, const Variant **params, int count);
        
        _FORCE_INLINE_ void setOCObject(id object) {
            this->object = object;
        }
        _FORCE_INLINE_ id getOCObject(){
            return object;
        }
        
    CLASS_END
}

#endif //VOIPPROJECT_OBJC_INSTANCE_H
#endif
