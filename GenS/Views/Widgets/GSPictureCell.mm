//
//  GSPictureCell.m
//  GenS
//
//  Created by mac on 2017/6/24.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "Page.h"
#import "GSPictureCell.h"
#import "DIManager.h"
#import "MTNetCacheManager.h"

using namespace nl;
using namespace hirender;

@implementation GSPictureCell {
    Ref<Page> _page;
    Ref<HTTPClient> _client;
}

- (void)setPage:(void *)page {
    _page = (nl::Page *)page;
    if (_client) {
        _client->cancel();
        _client = NULL;
    }
    
    NSString *url = [NSString stringWithUTF8String:_page->getPicture().c_str()];
    DIItem *item = [[DIManager defaultManager] itemWithURLString:url];
    if ([[NSFileManager defaultManager] fileExistsAtPath:item.path]) {
        [self setImagePath:item.path];
    }else {
        _client = _page->makeClient();
        __weak GSPictureCell *that = self;
        self.image = [UIImage imageNamed:@"no_image"];
        _client->setOnComplete(C([=](HTTPClient *c, const string &path){
            if (that) {
                GSPictureCell *sthat = that;
                if (c->getError().empty()) {
                    [sthat setImagePath:[NSString stringWithUTF8String:path.c_str()]];
                }else {
                    sthat.image = [UIImage imageNamed:@"failed"];
                }
                sthat->_client = NULL;
            }
        }));
        _client->start();
    }
}

- (void)setImage:(UIImage *)image {
    [super setImage:image];
}

- (void)setImagePath:(NSString *)imagePath {
    _imagePath = imagePath;
    
    self.image = [UIImage imageNamed:@"no_image"];
    [self.memCache loadImage:imagePath
                       block:^(NSString *path, UIImage *image) {
                           if ([_imagePath isEqualToString:path]) {
                               if (image) {
                                   self.image = image;
                               }else {
                                   self.image = [UIImage imageNamed:@"failed"];
                               }
                           }
                       }];
    
}

- (void)dealloc {
    if (_client) {
        _client->cancel();
    }
}

@end
