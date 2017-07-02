//
//  ObjcScript.h
//  hirender_iOS
//
//  Created by gen on 16/9/17.
//  Copyright © 2016年 gen. All rights reserved.
//

#ifdef __OBJC__

#ifndef VOIPPROJECT_OBJC_SCRIPT_H
#define VOIPPROJECT_OBJC_SCRIPT_H

#include <core/script/Script.h>
#include <mutex>

using namespace hicore;

namespace hiscript {
    class ObjcScript : public Script {
        
    protected:
        virtual ScriptClass *makeClass() const;
        virtual void _attach(ScriptInstance *sins, ScriptClass *clz) const {}
    public:
        virtual ScriptInstance *newBuff(const string &cls_name, HObject *target, const Variant **params, int count) const;
        _FORCE_INLINE_ ObjcScript() : Script("objc") {
        }
    };
}

#endif /* VOIPPROJECT_OBJC_SCRIPT_H */

#endif //__OBJC__
