//
//  GSHomeController.m
//  GenShelf
//
//  Created by Gen on 16/2/20.
//  Copyright © 2016年 AirRaidClub. All rights reserved.
//

#import "GSHomeController.h"
#import "GSShelfViewController.h"
#import "GSShelfsViewController.h"
#import "GSLibraryViewController.h"
#import "RKDropdownAlert.h"
#import "GCoverView.h"
#import "GlobalsDefine.h"
#import "DIManager.h"
#import "MTAlertView.h"
#include "../Common/Models/Book.h"
#include "../Common/Models/Shop.h"

using namespace nl;
static __weak GSHomeController *GS_currentController = NULL;

@interface NSString (Version)

- (BOOL)greaterVersion:(NSString *)version;

@end

@implementation NSString (Version)

- (BOOL)greaterVersion:(NSString *)version {
    NSArray *vs1 = [self componentsSeparatedByString:@"."];
    NSArray *vs2 = [self componentsSeparatedByString:@"."];
    for (NSInteger i = 0, t = vs1.count; i < t; ++i) {
        NSInteger vi1 = [[vs1 objectAtIndex:i] integerValue];
        NSInteger vi2 = 0;
        if (vs2.count > i) {
            vi2 = [[vs2 objectAtIndex:i] integerValue];
        }
        if (vi1 > vi2) {
            return true;
        }else if (vi1 < vi2)
            return false;
    }
    return false;
}

@end

@interface GSHomeController () <DIItemDelegate, MTAlertViewDelegate>

@end

@implementation GSHomeController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.items = @[[GSideMenuItem itemWithController:[[GSShelfViewController alloc] init]
                                                   image:[UIImage imageNamed:@"squares"]],
                       [GSideMenuItem itemWithController:[[GSLibraryViewController alloc] init]
                                                   image:[UIImage imageNamed:@"home"]],
                       [GSideMenuItem itemWithController:[[GSShelfsViewController alloc] init]
                                                   image:[UIImage imageNamed:@"setting"]]];
        
        if (Book::getLocalBooks().size() == 0) {
            if (Shop::getCurrentShop()) {
                self.selectedIndex = 1;
            }else self.selectedIndex = 2;
        }else {
            self.selectedIndex = 0;
        }
        GS_currentController = self;
        
    }
    return self;
}

- (void)dealloc {
    if (GS_currentController == self) {
        GS_currentController = nil;
    }
}

+ (void)setNevIndex:(int)idx {
    GS_currentController.selectedIndex = idx;
}

- (void)sideMenuSelect:(NSUInteger)index {
    [self closeMenu];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self requestVersion];
}

- (void)onFailed:(NSNotification *)notification {
//    if ([notification.object isKindOfClass:[GSModelNetBook class]]) {
//        GSModelNetBook *item = notification.object;
//        [RKDropdownAlert title:[NSString stringWithFormat:local(Download failed), item.title]
//               backgroundColor:[UIColor redColor]
//                     textColor:[UIColor whiteColor]];
//    }
}

- (void)requestVersion {
    DIItem *item = [[DIManager defaultManager] itemWithURLString:@"https://raw.githubusercontent.com/dbsGen/GenShelf_Versions/master/index.json"];
    item.delegate = self;
    [item start];
}

- (void)itemComplete:(DIItem *)item {
    NSString *data = [NSString stringWithContentsOfFile:item.path
                                               encoding:NSUTF8StringEncoding
                                                  error:nil];
    JSONNODE *node = json_parse(data.UTF8String);
    if (node) {
        JSONNODE *ios_node = json_get(node, "ios");
        if (ios_node) {
            JSONNODE *version_node = json_get(ios_node, "version");
            JSONNODE *url_node = json_get(ios_node, "url");
            JSONNODE *des_node = json_get(ios_node, "des");
            if (version_node && url_node && des_node) {
                char *version_str = json_as_string(version_node);
                char *url_str = json_as_string(url_node);
                char *des_str = json_as_string(des_node);
                if (version_str && url_str && des_str) {
                    NSString *vs = [NSString stringWithUTF8String:version_str];
                    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
                    if ([vs greaterVersion:version]) {
                        MTAlertView *alert = [[MTAlertView alloc] initWithTitle:local(Will upgrade)
                                                                        content:[NSString stringWithUTF8String:des_str]
                                                                          image:nil
                                                                        buttons:local(YES), local(NO), nil];
                        alert.delegate = self;
                        alert.customerData = [NSString stringWithUTF8String:url_str];
                        [alert show];
                    }
                    
                    json_free(version_str);
                    json_free(url_str);
                    json_free(des_str);
                }
            }
        }
        json_delete(node);
    }
}

- (void)alertView:(MTAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
    if (index == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:alertView.customerData]];
    }
}

@end
