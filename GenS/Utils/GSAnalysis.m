//
//  GSAnalysis.m
//  GenS
//
//  Created by mac on 2017/7/1.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSAnalysis.h"
#import "DIManager.h"
#import "libjson.h"
#import "OpenUDID.h"
#import <UIKit/UIKit.h>

#define AnalysisURL @"http://112.74.13.80:3000/analysis"

BOOL compare(const char *chs, const char *cmp, int len) {
    for (int i = 0; i  < len; ++i) {
        if (*(chs+i) != *(cmp+i)) {
            return false;
        }
    }
    return true;
}

void read_ip_address(const char *str, char *ip_str, char *address_str) {
    const char *ch = str;
    int status = 0;
    while (*ch) {
        if (status == 0) {
            if (*ch == 'i' && *(ch + 1) == 'p' && *(ch + 2) == ':') {
                ch += 2;
                status = 1;
            }else if (compare(ch, "address:", 8)) {
                ch += 7;
                status = 3;
            }
        }else if (status == 1) {
            if (*ch == '\'') {
                status = 2;
            }
        }else if (status == 2) {
            if (*ch == '\'') {
                status = 0;
            }else {
                *(ip_str++) = *ch;
            }
        }else if (status == 3) {
            if (*ch == '\'') {
                status = 4;
            }
        }else if (status == 4) {
            if (*ch == '\'') {
                status = 0;
            }else {
                *(address_str++) = *ch;
            }
        }
        ++ch;
    }
}

@implementation GSAnalysis

+ (void)run {
    DIItem *item = [[DIManager defaultManager] itemWithURLString:@"http://ip.chinaz.com/getip.aspx"];
    item.block = ^(DIItem* item, DICallbackType type, id data){
        if (type == DICallbackComplete) {
            NSString *content = [NSString stringWithContentsOfFile:item.path encoding:NSUTF8StringEncoding
                                                             error:nil];
            
            char ip_cstr[30] = {0};
            char address_cstr[50] = {0};
            read_ip_address(content.UTF8String, ip_cstr, address_cstr);
            NSString *ip_str = [NSString stringWithUTF8String:ip_cstr],
            *address_str = [NSString stringWithUTF8String:address_cstr];
            if (ip_str && address_str) {
                DIItem *nitem = [[DIManager defaultManager] itemWithURLString:AnalysisURL];
                nitem.readCacheWhenError = NO;
                
                NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
                nitem.datas = @{@"ip": ip_str,
                                @"address": address_str,
                                @"udid": [OpenUDID value],
                                @"os": @"ios",
                                @"os_version": [UIDevice currentDevice].systemVersion,
                                @"device": [UIDevice currentDevice].model,
                                @"version": version};
                nitem.method = @"POST";
                nitem.block = ^(DIItem* item, DICallbackType type, id data){
                    if (type == DICallbackComplete) {
                        NSLog(@"Analysis complete");
                    }
                };
                [nitem start];
            }
        }
    };
    [item start];
}

@end
