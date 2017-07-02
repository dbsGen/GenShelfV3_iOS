//
//  ObjcClass.h
//  hirender_iOS
//
//  Created by gen on 16/9/17.
//  Copyright © 2016年 gen. All rights reserved.
//

#ifdef __OBJC__
#ifndef VOIPPROJECT_OBJC_CLASS_H
#define VOIPPROJECT_OBJC_CLASS_H

#include <core/script/ScriptClass.h>
#include "../script_define.h"

using namespace hicore;

namespace hiscript {
    CLASS_BEGIN_N(ObjcClass, ScriptClass)
        Class clz;
        
    protected:
        virtual ScriptInstance *makeInstance() const;
        
    public:
        virtual Variant apply(const StringName &name, const Variant **params, int count) const;
        void setOCClass(Class clz) {
            this->clz = clz;
        }
        Class getOCClass() {
            return this->clz;
        }
        
    CLASS_END
}
#endif //VOIPPROJECT_OBJC_CLASS_H
#endif
