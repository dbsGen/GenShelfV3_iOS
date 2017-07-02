//
//  GSLibraryViewController.m
//  GenS
//
//  Created by mac on 2017/5/16.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSLibraryViewController.h"
#import "GlobalsDefine.h"
#import "GSideMenuController.h"
#import "GSSearchViewController.h"
#import "GSShopCell.h"
#import "GSBottomLoadingCell.h"
#import "Book.h"
#import "Shop.h"
#import "SRRefreshView.h"
#import "RKDropdownAlert.h"
#import "GSBookInfoViewController.h"
#import "GCoverView.h"
#import "GSLoadingView.h"
#import "GSCoverSelectView.h"
#import "GSHomeController.h"
#import "GSTitleInnerButton.h"
#include <utils/NotificationCenter.h>

using namespace hicore;
using namespace nl;
using namespace hirender;


static BOOL _GSLibrary_reload = YES;

@interface GSLibraryViewController () <UITableViewDelegate, UITableViewDataSource, SRRefreshDelegate, GSCoverSelectViewDelegate> {
@public
    vector<Ref<nl::Book> > _books;
    Ref<nl::Library>    _library;
    
    SRRefreshView       *_refreshView;
    GSBottomLoadingCell *_loadingCell;
    
    GSLoadingView       *_loadingView;
    BOOL                _loaded;
    int                 _index;
    
    GSTitleInnerButton  *_titleButton;
    UIBarButtonItem     *_searchButton;
}

@end

@implementation GSLibraryViewController {
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = local(Library);
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"]
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(openMenu)];
        _searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(searchClicked)];
        
        __weak GSLibraryViewController *that = self;
        NotificationCenter::getInstance()->listen(Shop::NOTIFICATION_SHOP_CHANGED, C([=](const Ref<Shop> &shop){
            GSLibraryViewController *sthat = that;
            if (!sthat.isViewLoaded) return;
            if (!sthat->_library) {
                if (shop)
                    [sthat reloadLibrary];
            }else if (sthat->_library->getShop() != *shop) {
                sthat->_library = nil;
                [sthat reloadLibrary];
            }
        }));
    }
    return self;
}

+ (void)setReloadCache:(BOOL)reload {
    _GSLibrary_reload = reload;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                              style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
    _refreshView = [[SRRefreshView alloc] initWithHeight:32];
    _refreshView.delegate = self;
    [_tableView addSubview:_refreshView];
    [_refreshView update:64];
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    _loadingCell = [[GSBottomLoadingCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:@"bottom_loading"];
    _loadingCell.status = GSBottomCellStatusWhite;
    
    _loadingView = [[GSLoadingView alloc] initWithFrame:self.view.bounds];
    [_loadingView.button addTarget:self
                            action:@selector(buttonClicked)
                  forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_loadingView];
    
    
    GSTitleInnerButton *button = [[GSTitleInnerButton alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    NSString *string = local(Library);
    [button setTitle:string
            forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor]
                 forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    CGRect rect = [string boundingRectWithSize:CGSizeMake(300, 30)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:@{NSFontAttributeName:button.titleLabel.font}
                                       context:nil];
    button.frame = CGRectMake(0, 0, 300, rect.size.height);
    [button addTarget:self
               action:@selector(libraryClicked)
     forControlEvents:UIControlEventTouchUpInside];
    
    _titleButton = button;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openMenu {
    [self.sideMenuController openMenu];
}

- (void)searchClicked {
    [self.navigationController pushViewController:[[GSSearchViewController alloc] initWithLibrary:*_library]
                                         animated:YES];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _books.size() ? _books.size() + 1 : _books.size();
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row < _books.size() ? 80 : 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < _books.size()) {
        static NSString *cellIdentifier = @"normal";
        GSShopCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[GSShopCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:cellIdentifier];
        }
        const Ref<Book> &book = _books[indexPath.row];
        cell.titleLabel.text = [NSString stringWithUTF8String:book->getName().c_str()];
        cell.imageUrl = [NSString stringWithUTF8String:book->getThumb().c_str()];
        cell.content = [NSString stringWithUTF8String:book->getSubtitle().c_str()];
        return cell;
    }else {
        [self loadMore];
        return _loadingCell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < _books.size()) {
        GSBookInfoViewController *ctrl = [[GSBookInfoViewController alloc] initWithBook:*_books[indexPath.row]
                                                                                library:*_library
                                                                                   shop:*nl::Shop::getCurrentShop()];
        GCoverView *cover = [[GCoverView alloc] initWithController:ctrl];
        __weak GCoverView *_cover = cover;
        ctrl.closeBlock = ^() {
            [_cover miss];
        };
        __weak GSLibraryViewController *that = self;
        ctrl.pushController = ^(UIViewController *c) {
            [that.sideMenuController presentViewController:c animated:YES
                                                  completion:nil];
        };
        [cover showInView:self.sideMenuController.view];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [_refreshView scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [_refreshView scrollViewDidEndDraging];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadLibrary];
}

- (void)reloadLibrary {
    if (nl::Shop::getCurrentShop()) {
        if (!_library) {
            _library = new nl::Library;
            const Ref<Shop> &shop = nl::Shop::getCurrentShop();
            shop->setupLibrary(*_library);
            NSString *string = [NSString stringWithUTF8String:shop->getName().c_str()];
            [_titleButton setTitle:string
                          forState:UIControlStateNormal];
            _loadingView.hidden = NO;
            _loadingView.alpha = 1;
            [_loadingView start];
            [self reloadData];
        }else if (_GSLibrary_reload){
            [self reloadData];
        }
    }
    _GSLibrary_reload = NO;
    if (Shop::getCurrentShop()) {
        self.navigationItem.rightBarButtonItem = _searchButton;
        self.navigationItem.titleView = _titleButton;
    }else {
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.titleView = nil;
        _loadingView.hidden = NO;
        _loadingView.alpha = 1;
        _loadingView.tag = 1;
        [_loadingView message:local(Empty install one)
                       button:local(go)];
    }
}

- (void)reloadData {
    if (_loadingCell.status == GSBottomCellStatusLoading) {
        [_refreshView endRefresh];
        return;
    }
    _loadingCell.status = GSBottomCellStatusLoading;
    
    StringName shop_id = nl::Shop::getCurrentShop()->getIdentifier();
    _index = 0;
    Variant idx(_index);
    __weak GSLibraryViewController *that = self;
    Variant call(C([=](bool success, RefArray arr, bool no_more){
        if (that) {
            GSLibraryViewController *sthat = that;
            if (success) {
                sthat->_books.clear();
                for (int i = 0, t = (int)arr.size(); i < t; ++i) {
                    Book *book = arr.at(i).get<nl::Book>();
                    book->setShopId(shop_id);
                    sthat->_books.push_back(book);
                }
                _loaded = YES;
                [sthat.tableView reloadData];
                [_loadingView stop];
                [UIView transitionWithView:_loadingView
                                  duration:0.3
                                   options:UIViewAnimationCurveEaseOut
                                animations:^{
                                    _loadingView.alpha = 0;
                                } completion:^(BOOL finished) {
                                    _loadingView.hidden = YES;
                                }];
            }else {
                [sthat->_loadingView failed];
                sthat->_loadingView.tag = 2;
                [sthat->_loadingView message:local(Network error)
                                      button:local(Refresh)];
            }
            [sthat->_refreshView endRefresh];
            bool nm = sthat->_books.size() == 0 || no_more;
            sthat->_loadingCell.status = nm?GSBottomCellStatusNoMore:GSBottomCellStatusHasMore;
        }
    }));
    
    pointer_vector vs{&idx, &call};
    _library->apply("load", vs);
}

- (void)loadMore {
    if (_loadingCell.status == GSBottomCellStatusHasMore) {
        _loadingCell.status = GSBottomCellStatusLoading;
        Variant idx(++_index);
        StringName shop_id = nl::Shop::getCurrentShop()->getIdentifier();
        __weak GSLibraryViewController *that = self;
        Variant call(C([=](bool success, RefArray arr, bool no_more){
            if (that) {
                GSLibraryViewController *sthat = that;
                if (success) {
                    if (arr.size()) {
                        NSMutableArray *array = [NSMutableArray array];
                        for (int i = 0, t = (int)arr.size(); i < t; ++i) {
                            [array addObject:[NSIndexPath indexPathForRow:sthat->_books.size()
                                                                inSection:0]];
                            Book *book = arr.at(i).get<nl::Book>();
                            book->setShopId(shop_id);
                            sthat->_books.push_back(book);
                        }
                        [sthat.tableView insertRowsAtIndexPaths:array
                                              withRowAnimation:UITableViewRowAnimationBottom];
                        _loadingCell.status = no_more ? GSBottomCellStatusNoMore : GSBottomCellStatusHasMore;
                    }else {
                        _loadingCell.status = GSBottomCellStatusNoMore;
                    }
                }else {
                    [RKDropdownAlert title:local(Network error)
                           backgroundColor:RED_COLOR
                                 textColor:[UIColor whiteColor]];
                    _loadingCell.status = GSBottomCellStatusHasMore;
                }
                [sthat->_refreshView endRefresh];
            }
        }));
        pointer_vector vs{&idx, &call};
        _library->apply("load", vs);
    }
}

- (void)slimeRefreshStartRefresh:(SRRefreshView*)refreshView {
    [self reloadData];
}

- (void)libraryClicked {
    CGRect rect = self.view.bounds;
    GSCoverSelectView *coverView = [[GSCoverSelectView alloc] initWithFrame:CGRectMake((rect.size.width - 160)/2, 56, 160, 200)];
    NSMutableArray *arr = [NSMutableArray array];
    auto &shops = Shop::getLocalShops();
    int count = 0, selected = 0;
    for (auto it = shops->begin(), _e = shops->end(); it != _e; ++it) {
        Ref<Shop> shop = *it;
        if (shop == Shop::getCurrentShop()) {
            selected = count;
        }
        [arr addObject:[NSString stringWithUTF8String:shop->getName().c_str()]];
        ++count;
    }
    coverView.params = arr;
    coverView.selected = selected;
    coverView.delegate = self;
    [coverView show];
    [_titleButton extend:YES];
}

- (void)coverSelectView:(GSCoverSelectView *)view selected:(NSInteger)index {
    [view miss];
    auto &shops = Shop::getLocalShops();
    auto it = shops->begin();
    for (NSInteger i = 0; i < index; ++i) {
        ++it;
    }
    const Ref<Shop> &shop = *it;
    if (shop) {
        Shop::setCurrentShop(shop);
        [_titleButton setTitle:[NSString stringWithUTF8String:shop->getName().c_str()]
                      forState:UIControlStateNormal];
        [_titleButton updateTriPosition];
    }
}

- (void)coverSelectViewMiss:(GSCoverSelectView *)view {
    [_titleButton extend:NO];
}

- (void)buttonClicked {
    if (_loadingView.tag == 1) {
        [GSHomeController setNevIndex:2];
    }else {
        [_loadingView start];
        [self reloadData];
    }
}

@end
