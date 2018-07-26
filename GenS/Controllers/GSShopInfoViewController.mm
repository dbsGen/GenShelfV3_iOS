//
//  GSShopInfoViewController.m
//  GenS
//
//  Created by gen on 16/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import "GSShopInfoViewController.h"
#import "Shop.h"
#import "GSRadiusImageView.h"
#import "DIManager.h"
#import "MTNetCacheManager.h"
#import "GlobalsDefine.h"
#import "MTPaddyButton.h"
#include <utils/NotificationCenter.h>
#import "RKDropdownAlert.h"
#import "MTAlertView.h"

using namespace nl;

static BOOL isShopListener_inited = false;

void installComplete(void *s) {
    Shop *shop = (Shop*)s;
    if (shop->isLocalize()) {
        [RKDropdownAlert title:[NSString stringWithFormat:local(Installed shop), [NSString stringWithUTF8String:shop->getName().c_str()]]
               backgroundColor:GREEN_COLOR
                     textColor:[UIColor whiteColor]];
    }else {
        [RKDropdownAlert title:local(Install failed)
               backgroundColor:RED_COLOR
                     textColor:[UIColor whiteColor]];
    }
}
void deleteComplete(void *s) {
    Shop *shop = (Shop*)s;
    [RKDropdownAlert title:[NSString stringWithFormat:local(Removed shop), [NSString stringWithUTF8String:shop->getName().c_str()]]
           backgroundColor:GREEN_COLOR
                 textColor:[UIColor whiteColor]];
}

@interface GSPressButton : UIButton

@end

@implementation GSPressButton

- (void)setHighlighted:(BOOL)highlighted {
    if (highlighted) {
        self.alpha = 0.5;
    }else self.alpha = 1;
}

- (void)setEnabled:(BOOL)enabled {
    self.userInteractionEnabled = enabled;
    if (enabled) {
        self.alpha = 1;
    }else
        self.alpha = 0.5;
}

@end

@interface GSShopInfoViewController () <DIItemDelegate>

@end

@implementation GSShopInfoViewController {
    Ref<Shop> _localShop;
    Ref<Shop> _onlineShop;
    Ref<Shop> _shop;
    GSRadiusImageView *_imageView;
    UILabel *_titleLabel;
    UILabel *_descriptionLabel;
    UILabel *_hostLabel;
    UIScrollView *_scrollView;
    
    DIItem *_currentRequest;
    NSString *_imageUrl;
    
    UIButton *_closeButton;
    UIButton *_settingButton;
    UIButton *_installbutton;
    UIButton *_hostButton;
    Ref<Callback> remove_callback;
    Ref<Callback> install_callback;
    
}

const Ref<Shop> &GSShopInfoGetShop(GSShopInfoViewController *that) {
    return that->_shop;
}

- (id)initWithLocalShop:(void *)localShop onlineShop:(void *)onlineShop {
    self = [super init];
    if (self) {
        _localShop = (nl::Shop*)localShop;
        _onlineShop = (nl::Shop*)onlineShop;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_onlineShop && _localShop) {
        _shop = _onlineShop;
    }else if (_onlineShop){
        _shop = _onlineShop;
    }else {
        _shop = _localShop;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _imageView = [[GSRadiusImageView alloc] initWithFrame:CGRectMake(10, 10, 60, 60)];
    _imageView.radius = 5;
    [self.view addSubview:_imageView];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 10, self.view.bounds.size.width - 110, 36)];
    _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    _titleLabel.font = [UIFont boldSystemFontOfSize:14];
    _titleLabel.text = [NSString stringWithUTF8String:_shop->getName().c_str()];
    _titleLabel.textColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
    
    [self.view addSubview:_titleLabel];
    
    _hostLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 46, self.view.bounds.size.width - 110, 14)];
    _hostLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    _hostLabel.font = [UIFont systemFontOfSize:14];
    _hostLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1];
    _hostLabel.text = [NSString stringWithUTF8String:_shop->getHost().c_str()];
    [self.view addSubview:_hostLabel];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 80, self.view.bounds.size.width - 20, self.view.bounds.size.height - 134)];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_scrollView];
    _descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 20, self.view.bounds.size.height - 134)];
    _descriptionLabel.numberOfLines = 0;
    _descriptionLabel.font = [UIFont systemFontOfSize:14];
    _descriptionLabel.textColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1];
    [_scrollView addSubview:_descriptionLabel];
    
    UIView *toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 44,
                                                               self.view.bounds.size.width, 44)];
    toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    toolBar.backgroundColor = [UIColor whiteColor];
    toolBar.layer.shadowColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1].CGColor;
    toolBar.layer.shadowOpacity = 1;
    toolBar.layer.shadowRadius = 2;
    toolBar.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:toolBar];
    
    [self setImageUrl:[NSString stringWithUTF8String:_shop->getIcon().c_str()]];
    
    _hostButton = [[UIButton alloc] initWithFrame:CGRectMake(80, 10, self.view.bounds.size.width - 90, 60)];
    _hostButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_hostButton addTarget:self
                    action:@selector(gotoHost)
          forControlEvents:UIControlEventTouchUpInside];
    [_hostButton setBackgroundImage:[UIImage imageNamed:@"black"]
                           forState:UIControlStateHighlighted];
    _hostButton.layer.cornerRadius = 5;
    _hostButton.clipsToBounds = YES;
    _hostButton.alpha = 0.2;
    [self.view addSubview:_hostButton];
    
    _closeButton = [[MTPaddyButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 44, 0, 44, 44)];
    [_closeButton setImage:[UIImage imageNamed:@"close"]
                  forState:UIControlStateNormal];
    _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    _closeButton.alpha = 0.6;
    [self.view addSubview:_closeButton];
    
    [_closeButton addTarget:self
                     action:@selector(closeChecked)
           forControlEvents:UIControlEventTouchUpInside];
    _closeButton.layer.shadowColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1].CGColor;
    _closeButton.layer.shadowRadius = 1;
    _closeButton.layer.shadowOpacity = 1;
    _closeButton.layer.shadowOffset = CGSizeZero;
    
    UIView *cont = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 250) / 2, 2, 250, 40)];
    
    _settingButton = [GSPressButton buttonWithType:UIButtonTypeCustom];
    _settingButton.frame = CGRectMake(2, 0, 120, 40);
    [_settingButton setTitle:local(Settings2)
                    forState:UIControlStateNormal];
    _settingButton.backgroundColor = GREEN_COLOR;
    _settingButton.layer.cornerRadius = 5;
    _settingButton.clipsToBounds = YES;
    [_settingButton addTarget:self
                       action:@selector(settingClicked:)
             forControlEvents:UIControlEventTouchUpInside];
    [cont addSubview:_settingButton];
    
    _installbutton = [GSPressButton buttonWithType:UIButtonTypeCustom];
    _installbutton.frame = CGRectMake(126, 0, 120, 40);
    _installbutton.backgroundColor = BLUE_COLOR;
    [_installbutton setTitle:local(Install)
                    forState:UIControlStateNormal];
    _installbutton.layer.cornerRadius = 5;
    _installbutton.clipsToBounds = YES;
    [_installbutton addTarget:self
                       action:@selector(installClicked)
             forControlEvents:UIControlEventTouchUpInside];
    [cont addSubview:_installbutton];
    cont.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [toolBar addSubview:cont];
    [self checkLocal];
}

- (void)viewWillAppear:(BOOL)animated {
    __weak GSShopInfoViewController *that = self;
    remove_callback = C([=](void *shop){
        if (that && *GSShopInfoGetShop(that) == shop)
            [that removedItem];
    });
    install_callback = C([=](void *shop){
        if (that && *GSShopInfoGetShop(that) == shop)
            [that installedItem:shop];
    });
    gr::NotificationCenter::getInstance()->listen(nl::Shop::NOTIFICATION_REMOVED,
                                                        remove_callback);
    gr::NotificationCenter::getInstance()->listen(nl::Shop::NOTIFICATION_INSTALLED,
                                                        install_callback);
    if (!isShopListener_inited) {
        isShopListener_inited = true;
        gr::NotificationCenter::getInstance()->listen(nl::Shop::NOTIFICATION_REMOVED,
                                                            C(&deleteComplete));
        gr::NotificationCenter::getInstance()->listen(nl::Shop::NOTIFICATION_INSTALLED,
                                                            C(&installComplete));
    }
}
- (void)viewDidDisappear:(BOOL)animated {
    
    gr::NotificationCenter::getInstance()->remove(nl::Shop::NOTIFICATION_REMOVED,
                                                        remove_callback);
    gr::NotificationCenter::getInstance()->remove(nl::Shop::NOTIFICATION_INSTALLED,
                                                        install_callback);
//    remove_callback = nil;
//    install_callback = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _hostButton.frame = CGRectMake(80, 12, self.view.bounds.size.width - 90, 56);
    _titleLabel.frame = CGRectMake(80, 10, self.view.bounds.size.width - 110, 36);
    _hostLabel.frame = CGRectMake(80, 46, self.view.bounds.size.width - 90, 14);
    [self setContent:[NSString stringWithUTF8String:_shop->getDescription().c_str()]];
}

- (void)closeChecked {
    if (self.closeBlock) {
        self.closeBlock();
    }
}

- (void)setImageUrl:(NSString *)imageUrl {
    if (_currentRequest) {
        [_currentRequest cancel];
        _currentRequest = NULL;
    }
    _imageUrl = imageUrl;
    _imageView.image = [UIImage imageNamed:@"no_image"];
    if (imageUrl) {
        [[MTNetCacheManager defaultManager] getImageWithUrl:imageUrl
                                                      block:^(id result) {
                                                          if (result) {
                                                              _imageView.image = result;
                                                          }else {
                                                              _currentRequest = [[DIManager defaultManager] itemWithURLString:imageUrl];
                                                              _currentRequest.delegate = self;
                                                              [_currentRequest start];
                                                          }
                                                      }];
    }
}

- (void)itemComplete:(DIItem *)item {
    NSData *data = [NSData dataWithContentsOfFile:item.path];
    [[MTNetCacheManager defaultManager] setData:data
                                        withUrl:_imageUrl];
    _currentRequest = NULL;
    _imageView.image = [UIImage imageWithData:data];
}

- (void)setContent:(NSString *)content {
    _descriptionLabel.text = [content stringByReplacingOccurrencesOfString:@"<p>"
                                                                withString:@"\n"];
    CGRect rect = _descriptionLabel.frame;
    CGFloat width = _scrollView.bounds.size.width;
    rect.size = [_descriptionLabel sizeThatFits:CGSizeMake(width - 20, 999)];
    _descriptionLabel.frame = rect;
    _scrollView.contentSize = rect.size;
}

- (void)installClicked {
    _installbutton.enabled = NO;
    if (_shop->isLocalize())
        _shop->remove();
    else {
        [RKDropdownAlert title:local(Install OK)
               backgroundColor:BLUE_COLOR
                     textColor:[UIColor whiteColor]];
        _shop->install();
    }
}

- (void)removedItem {
    [self checkLocal];
    _installbutton.enabled = YES;
}

- (void)installedItem:(void*)shop {
    if (_localShop) {
        Shop *s = (Shop*)shop;
        _localShop->setVersion(s->getVersion());
    }
    [self checkLocal];
    _installbutton.enabled = YES;
}

- (void)settingClicked:(UIButton *)button {
    if (button.enabled && _installbutton.enabled) {
        if (_shop->isLocalize()) {
            _settingBlock(*_shop);
        }else if (_localShop->isLocalize()) {
            _settingBlock(*_localShop);
        }
    }
}

- (void)gotoHost {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_hostLabel.text]];
}

- (void)checkLocal {
    int status = 0;
    if (_onlineShop && _localShop) {
        if (_onlineShop->getVersion() > _localShop->getVersion()) {
            _shop = _onlineShop;
            status = 2;
        }else {
            _shop = _localShop->isLocalize() ? _localShop : _onlineShop;
            status = _shop->isLocalize() ? 1 : 0;
        }
    }else if (_onlineShop) {
        _shop = _onlineShop;
        status = _shop->isLocalize() ? 1 : 0;
    }else {
        _shop = _localShop;
        status = _shop->isLocalize() ? 1 : 0;
    }
    if (status == 1) {
        _installbutton.backgroundColor = RED_COLOR;
        [_installbutton setTitle:local(Remove)
                        forState:UIControlStateNormal];
        _settingButton.enabled = YES;
    }else if (status == 0){
        _installbutton.backgroundColor = BLUE_COLOR;
        [_installbutton setTitle:local(Install)
                        forState:UIControlStateNormal];
        _settingButton.enabled = NO;
    }else if (status == 2) {
        _installbutton.backgroundColor = BLUE_COLOR;
        [_installbutton setTitle:local(Update)
                        forState:UIControlStateNormal];
        _settingButton.enabled = YES;
    }
}

@end
