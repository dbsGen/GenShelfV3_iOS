//
//  GSDownloadManager.m
//  GenS
//
//  Created by mac on 2017/5/18.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSDownloadManager.h"
#include <set>
#include "../../Common/Models/Shop.h"
#include "../../Common/Models/Chapter.h"
#include "../../Common/Models/Book.h"

using namespace nl;

#define GSDownloadManager_Path @"locals"

@implementation GSDownloadManager {
    NSMutableArray *_queue;
    std::set<void*> _indexes;
    DIItem *_doing;
    NSInteger ret_count;
    
    pointer_map _local_chapters;
}

static GSDownloadManager *_instance = NULL;

+ (instancetype)defaultManager {
    @synchronized (self) {
        if (_instance == NULL) {
            _instance = [[GSDownloadManager alloc] init];
        }
    }
    return _instance;
}

- (id)init {
    self = [super init];
    if (self) {
        _queue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)startItemWithUrl:(NSString *)url block:(void (^)(DIItem *))block {
    DIItem *item = [[DIManager defaultManager] itemWithURLString:url];
    block(item);
    if ((item.status == DIStatusNone || item.status == DIStatusPause) && _indexes.count((__bridge void*)item) == 0) {
        _indexes.insert((__bridge void*)item);
        [_queue addObject:item];
        [self checkAction];
    }
}

- (void)bringFirst:(NSString *)url {
    DIItem *item = [[DIManager defaultManager] itemWithURLString:url];
    if (_indexes.count((__bridge void*)item)) {
        [_queue removeObject:item];
        [_queue insertObject:item atIndex:0];
        if (_doing != item) {
            if (_doing) {
                [_doing pause];
                _doing = nil;
            }
            [self checkAction];
        }
    }
}

- (void)complete:(DIItem *)item {
    _doing = nil;
    _indexes.erase((__bridge void*)item);
    [_queue removeObject:item];
    item.block = nil;
    [self checkAction];
}

- (void)failed:(DIItem *)item {
    if (ret_count < 3) {
        ret_count ++;
        [item performSelector:@selector(start)
                   withObject:nil
                   afterDelay:0];
    }else {
        _doing = nil;
        _indexes.erase((__bridge void*)item);
        [_queue removeObject:item];
        item.block = nil;
        [self checkAction];
    }
}

- (void)checkAction {
    if (!_doing) {
        DIItem *item = _queue.firstObject;
        _doing = item;
        __weak GSDownloadManager *that = self;
        item.block = ^(DIItem* item, DICallbackType type, id data) {
            if (type == DICallbackComplete) {
                [that complete:item];
            }else if (type == DICallbackFailed) {
                [that failed:item];
            }
        };
        ret_count = 0;
        [item start];
    }
}

- (void)removeItems:(NSArray *)items {
    for (DIItem *item in items) {
        if (_indexes.count((__bridge void*)item) != 0) {
            [_queue removeObject:item];
            _indexes.erase((__bridge void*)item);
            if (_doing == item) {
                [_doing pause];
                _doing = nil;
            }
        }
    }
    [self checkAction];
}

- (void *)collect:(void *)c book:(void *)b shop:(void *)s {
    Shop *shop = (Shop*)s;
    Book *book = (Book*)b;
    Chapter *chapter = (Chapter*)c;
    
    auto it = _local_chapters.find(book);
    if (it == _local_chapters.end()) {
        ref_map *books = new ref_map;
        books->operator[](h(chapter->getName().c_str())) = chapter;
        
        Ref<Reader> reader = new Reader;
        Variant vcha(chapter);
        pointer_vector vs{&vcha};
        reader->apply("process", vs);
    }
    
    return nil;
}

@end
