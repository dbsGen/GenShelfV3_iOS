//
//  GSSearchViewController.m
//  GenS
//
//  Created by mac on 2017/5/16.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSSearchViewController.h"
#import "GlobalsDefine.h"
#import "GSLoadingView.h"
#import "SRRefreshView.h"
#import "GSShopCell.h"
#import "GSBottomLoadingCell.h"
#import "RKDropdownAlert.h"
#import "GSBookInfoViewController.h"
#import "GCoverView.h"
#import "GSideMenuController.h"
#include "../Common/Models/Shop.h"
#include "../Common/Models/Book.h"
#include <utils/network/HTTPClient.h>

using namespace nl;
using namespace hicore;
using namespace hirender;

@interface GSSearchViewController () <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, SRRefreshDelegate> {
    Ref<Library>    _library;
    Ref<HTTPClient> _client;
    vector<Ref<Book> >  _books;
    GSBottomLoadingCell *_loadingCell;
    
    UISearchBar     *_searchBar;
    NSString        *_searchKey;
    int             _index;
}

@property (nonatomic, strong) UITableView   *tableView;
@property (nonatomic, strong) SRRefreshView *refreshView;
@property (nonatomic, strong) GSLoadingView *loadingView;

@end

@implementation GSSearchViewController

- (id)initWithLibrary:(void *)library {
    self = [super init];
    if (self) {
        self.title = local(Search);
        _library = (Library*)library;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect bounds = self.view.bounds;
    
    _tableView = [[UITableView alloc] initWithFrame:bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    _refreshView = [[SRRefreshView alloc] init];
    _refreshView.slimeMissWhenGoingBack = YES;
    _refreshView.delegate = self;
    [_tableView addSubview:_refreshView];
    
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth| UIViewAutoresizingFlexibleHeight;
    _tableView.contentInset = UIEdgeInsetsMake(40, 0, 0, 0);
    [self.view addSubview:_tableView];
    
    _loadingView = [[GSLoadingView alloc] initWithFrame:bounds];
    [self.view addSubview:_loadingView];
    
    [_refreshView update:20 + self.navigationController.navigationBar.bounds.size.height + _searchBar.bounds.size.height];
    
    _searchBar = [[UISearchBar alloc] init];
    _searchBar.frame = CGRectMake(0, self.navigationController.navigationBar.bounds.size.height + 20, bounds.size.width, 40);
    _searchBar.placeholder = local(Input key words here);
    _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _searchBar.delegate = self;
    [self.view addSubview:_searchBar];
    
    _loadingCell = [[GSBottomLoadingCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:@"bottom_loading"];
    _loadingCell.status = GSBottomCellStatusWhite;
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_client) {
        _client->cancel();
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - search

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    _searchKey = searchBar.text;
    [_searchBar endEditing:YES];
    [self requestDatas];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    _searchKey = nil;
    [_searchBar endEditing:YES];
//    _datas = [NSMutableArray array];
    [_tableView reloadData];
//    [self updateLoadingStatus];
}

- (void)requestDatas {
    _loadingCell.status = GSBottomCellStatusLoading;
    _loadingView.hidden = NO;
    [_loadingView start];
    Variant v1(_searchBar.text.UTF8String);
    _index = 0;
    Variant idx(_index);
    __weak GSSearchViewController *that = self;
    Variant call(C([=](bool success, const RefArray &books, bool no_more){
        if (that) {
            GSSearchViewController *sthat = that;
            if (success) {
                [sthat->_loadingView stop];
                [UIView animateWithDuration:0.3 animations:^{
                    sthat->_loadingView.alpha = 0;
                } completion:^(BOOL finished) {
                    sthat->_loadingView.hidden = YES;
                }];
                sthat->_books.clear();
                for (int i = 0, t = (int)books.size(); i < t; ++i) {
                    sthat->_books.push_back(books.at(i));
                }
                [sthat.tableView reloadData];
                if (no_more) {
                    sthat->_loadingCell.status = GSBottomCellStatusNoMore;
                }else {
                    sthat->_loadingCell.status = books.size() ? GSBottomCellStatusHasMore : GSBottomCellStatusNoMore;
                }
            }else {
                [sthat->_loadingView failed];
            }
            sthat->_client = nil;
        }
    }));
    pointer_vector vs{&v1, &idx, &call};
    _client = (Ref<HTTPClient>)_library->apply("search", vs);
}


- (void)loadMore {
    if (_loadingCell.status == GSBottomCellStatusHasMore) {
        _loadingCell.status = GSBottomCellStatusLoading;
        Variant v1(_searchBar.text.UTF8String);
        Variant idx(++_index);
        __weak GSSearchViewController *that = self;
        Variant call(C([=](bool success, const RefArray &books, bool no_more){
            if (that) {
                GSSearchViewController *sthat = that;
                if (success) {
                    if (books.size()) {
                        NSMutableArray *array = [NSMutableArray array];
                        for (int i = 0, t = (int)books.size(); i < t; ++i) {
                            [array addObject:[NSIndexPath indexPathForRow:sthat->_books.size()
                                                                inSection:0]];
                            sthat->_books.push_back(books.at(i).get<nl::Book>());
                        }
                        [sthat.tableView insertRowsAtIndexPaths:array
                                              withRowAnimation:UITableViewRowAnimationBottom];
                        
                        sthat->_loadingCell.status = no_more ? GSBottomCellStatusNoMore: GSBottomCellStatusHasMore;
                    }else {
                        sthat->_loadingCell.status = GSBottomCellStatusNoMore;
                    }
                }else {
                    [RKDropdownAlert title:local(Network error)
                           backgroundColor:RED_COLOR
                                 textColor:[UIColor whiteColor]];
                    sthat->_loadingCell.status = GSBottomCellStatusHasMore;
                }
                [self->_refreshView endRefresh];
            }
        }));
        pointer_vector vs{&v1, &idx, &call};
        _client = (Ref<HTTPClient>)_library->apply("search", vs);
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row < _books.size() ? 80 : 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _books.size() ? _books.size() + 1 : _books.size();
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
        cell.content = [NSString stringWithUTF8String:book->getDes().c_str()];
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
        __weak GSSearchViewController *that = self;
        ctrl.pushController = ^(UIViewController *c) {
            [that.sideMenuController presentViewController:c animated:YES
                                                completion:nil];
        };
        [cover showInView:self.sideMenuController.view];
    }
}

@end
