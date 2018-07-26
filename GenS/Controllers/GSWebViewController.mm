//
//  GSWebViewController.m
//  GenS
//
//  Created by mac on 2017/7/25.
//  Copyright © 2017年 gen. All rights reserved.
//

#include <core/Callback.h>
#import <WebKit/WebKit.h>
#import "GSWebViewController.h"

using namespace gcore;

@interface GSWebViewController() <WKNavigationDelegate>

@end

@implementation GSWebViewController {
    RefCallback _callback;
    UIWebView *_webView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"done"]
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(doneClicked)];
    }
    return self;
}

- (void)setCallback:(void *)cb {
    _callback = (Callback*)cb;
}

- (void)setUrl:(NSURL *)url {
    _url = url;
    [_webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
//    _webView.delegate = self;
    if (self.url) {
        [_webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    }
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_webView];
}

- (void)doneClicked {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSURL *url = _webView.request.URL;
    if (!url || url.host.length == 0) {
        url = _webView.request.mainDocumentURL;
    }
    if (!url || url.host.length == 0) {
        url = [NSURL URLWithString:[_webView stringByEvaluatingJavaScriptFromString:@"window.location"]];
    }
    if (!url || url.host.length == 0) {
        url = self.url;
    }
    NSArray<NSHTTPCookie *> *cookies = [storage cookiesForURL:self.url];
    NSMutableString *string = [[NSMutableString alloc] init];
    [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [string appendFormat:@"%@=%@;", obj.name, obj.value];
    }];
    variant_vector vs{string.UTF8String};
    _callback->invoke(vs);
    [self.navigationController popViewControllerAnimated:YES];
}

@end
