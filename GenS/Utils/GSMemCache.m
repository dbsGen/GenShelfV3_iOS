//
//  GSMemCache.m
//  GenS
//
//  Created by mac on 2017/6/24.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSMemCache.h"
#import "UIImage+MultiFormat.h"

@implementation GSMemCache {
    NSMutableDictionary *_caches;
    NSMutableArray  *_cachesIndex;
    dispatch_queue_t _queue;
}

- (id)init {
    self = [super init];
    if (self) {
        _caches = [[NSMutableDictionary alloc] init];
        _cachesIndex = [[NSMutableArray alloc] init];
        _queue = dispatch_queue_create("my_queue", NULL);
    }
    return self;
}

- (void)loadImage:(NSString *)path block:(void (^)(NSString *path, UIImage *))block {
    UIImage *image = [_caches objectForKey:path];
    if (image) {
        [_cachesIndex removeObject:path];
        [_cachesIndex addObject:path];
        block(path, image);
    }else {
        dispatch_async(_queue, ^{
            UIImage *image = [UIImage sd_imageWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (image) {
                    while (_cachesIndex.count > 15) {
                        NSString *path = [_cachesIndex objectAtIndex:0];
                        [_cachesIndex removeObjectAtIndex:0];
                        [_caches removeObjectForKey:path];
                    }
                    [_caches setObject:image
                                forKey:path];
                    [_cachesIndex addObject:path];
                }
                block(path, image);
            });
        });
    }
}

@end
