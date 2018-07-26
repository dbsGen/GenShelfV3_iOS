//
//  GSUtils.cpp
//  GenS
//
//  Created by mac on 2017/9/3.
//  Copyright © 2017年 gen. All rights reserved.
//

#include "GSUtils.hpp"

NSDictionary *dic(const Map &map) {
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    for (auto it = map->begin(), _e = map->end(); it != _e; ++it) {
        [ret setObject:[NSString stringWithUTF8String:it->second]
                forKey:[NSString stringWithUTF8String:it->first.c_str()]];
    }
    return ret;
}
