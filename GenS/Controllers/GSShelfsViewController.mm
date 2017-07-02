//
//  GSShelfsViewController.m
//  GenS
//
//  Created by gen on 16/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import "GSShelfsViewController.h"
#import "GSideMenuController.h"
#import "GlobalsDefine.h"
#import "DIManager.h"
#import "Shop.h"
#import "GSShopCell.h"
#include <set>
#include <core/Data.h>
#import "GSShopInfoViewController.h"
#import "GCoverView.h"
#import "SRRefreshView.h"
#import "GSSettingViewController.h"

#define SUPPORTED_PACKAGE_VERSION 2

@interface GSShelfsViewController () <DIItemDelegate, UITableViewDelegate, UITableViewDataSource, SRRefreshDelegate> {
    vector<Ref<nl::Shop> > _displayShops;
    map<void*, Ref<nl::Shop> > _localShops;
    map<void*, Ref<nl::Shop> > _onlineShops;
}

@property (nonatomic, strong) SRRefreshView *refreshView;

@end

@implementation GSShelfsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = local(Settings);
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"]
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(openMenu)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    auto &shops = nl::Shop::getLocalShops();
    for (auto it = shops->begin(), _e = shops->end(); it != _e; ++it) {
        Ref<nl::Shop> shop = *it;
        _localShops[shop->getIdentifier()] = shop;
        _displayShops.push_back(shop);
    }
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_tableView];
    
    _refreshView = [[SRRefreshView alloc] initWithHeight:32];
    _refreshView.delegate = self;
    [_tableView addSubview:_refreshView];
    [_refreshView update:64];
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    [self requestData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)itemComplete:(DIItem *)item {
    FileData file(item.path.UTF8String);
    JSONNODE *node = json_parse(file.text());
    for (int i = 0, t = json_size(node); i < t; ++i) {
        JSONNODE *child = json_at(node, i);
        JSONNODE *id_node = json_get(child, "id");
        if (id_node) {
            Ref<nl::Shop> shop = nl::Shop::parseJson(child);
            if (shop && shop->getPackageVersion() <= SUPPORTED_PACKAGE_VERSION) {
                bool exist = false;
                for (auto it = _displayShops.begin(), _e = _displayShops.end(); it != _e; ++it) {
                    if ((*it)->getIdentifier() == shop->getIdentifier()) {
                        exist = true;
                        *it = shop;
                        break;
                    }
                }
                if (!exist) {
                    _displayShops.push_back(shop);
                }
                _onlineShops[shop->getIdentifier()] = shop;
            }
        }
    }
    json_delete(node);
    [_tableView reloadData];
    [self.refreshView endRefresh];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _displayShops.size();
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Normal";
    GSShopCell *cell = (GSShopCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[GSShopCell alloc] initWithStyle:UITableViewCellStyleDefault
                                 reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    Ref<nl::Shop> shop = _displayShops[indexPath.row];
    cell.titleLabel.text = [NSString stringWithUTF8String:shop->getName().c_str()];
    cell.content = [NSString stringWithUTF8String:shop->getDescription().c_str()];
    cell.imageUrl = [NSString stringWithUTF8String:shop->getIcon().c_str()];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Ref<nl::Shop> shop = _displayShops[indexPath.row];
    nl::Shop *onlineShop = NULL;
    nl::Shop *localShop = NULL;
    auto oit = _onlineShops.find(shop->getIdentifier());
    if (oit != _onlineShops.end()) {
        onlineShop = *oit->second;
    }
    auto lit = _localShops.find(shop->getIdentifier());
    if (lit != _localShops.end()) {
        localShop = *lit->second;
    }
    GSShopInfoViewController *ctrl = [[GSShopInfoViewController alloc] initWithLocalShop:localShop
                                                                              onlineShop:onlineShop];
    GCoverView *cover = [[GCoverView alloc] initWithController:ctrl];
    __weak GCoverView *_cover = cover;
    __weak GSShelfsViewController *that = self;
    ctrl.closeBlock = ^{
        [_cover miss];
    };
    ctrl.settingBlock = ^(void *shop){
        GSSettingViewController *c = [[GSSettingViewController alloc] initWithShop:shop];
        c.closeCoverBlock = ^{
            [_cover miss];
        };
        [that.sideMenuController presentViewController:[[UINavigationController alloc] initWithRootViewController:c]
                                              animated:YES
                                            completion:nil];
    };
    [cover showInView:self.sideMenuController.view];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.refreshView scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.refreshView scrollViewDidEndDraging];
}

- (void)openMenu {
    [self.sideMenuController openMenu];
}

- (void)requestData {
    self.refreshView.loading = YES;
    DIItem *item = [[DIManager defaultManager] itemWithURLString:@"https://raw.githubusercontent.com/dbsGen/GenShelf_Packages/master/index.json"];
    item.readCache = false;
    item.readCacheWhenError = true;
    item.delegate = self;
    [item start];
    
}

- (void)slimeRefreshStartRefresh:(SRRefreshView*)refreshView {
    [self requestData];
}

@end
