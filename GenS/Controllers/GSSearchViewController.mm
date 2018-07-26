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
#include "../Common/Models/SearchTip.h"
#import "GTween.h"
#include <utils/network/HTTPClient.h>

using namespace nl;
using namespace gcore;
using namespace gr;

#define CELL_HEIGHT 36

@protocol GSSearchResultViewDelegate <NSObject>

- (void)searchResultDidSelect:(NSString *)result;

@end

@interface GSSearchResultView : UIControl <UITableViewDelegate, UITableViewDataSource> {
    Array _results;
}

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, weak) id<GSSearchResultViewDelegate> delegate;

- (void)setResults:(const Array &)results;

@end

@implementation GSSearchResultView

- (void)setResults:(const Array &)results {
    _results = results;
    CGRect frame = self.frame;
    _tableView.frame = CGRectMake(0, 0, frame.size.width, CELL_HEIGHT * results.size());
    _tableView.hidden = results.size() == 0;
//    _tableView.editing = YES;
    [_tableView reloadData];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 0)];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [self addSubview:_tableView];
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    }
    return self;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self.delegate searchResultDidSelect:cell.textLabel.text];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _results ? _results.size() : 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        _results->erase(indexPath.row);
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        const char *chs = cell.textLabel.text.UTF8String;
        if (chs) SearchTip::removeKey(chs);
        [tableView deleteRowsAtIndexPaths:@[indexPath]
                         withRowAnimation:UITableViewRowAnimationLeft];
        [GTween cancel:tableView];
        GTween * tween =[GTween tween:tableView
                             duration:0.3
                                 ease:[GEaseCubicOut class]];
        [tween addProperty:[GTweenCGRectProperty property:@"frame"
                                                     from:tableView.frame
                                                       to:CGRectMake(0, 0, self.frame.size.width, CELL_HEIGHT)]];
        [tween start];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * const identifier = @"normal";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
    }
    cell.textLabel.text = [NSString stringWithUTF8String:_results.at(indexPath.row)];
    return cell;
}

@end

@interface GSSearchViewController () <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, SRRefreshDelegate, GSSearchResultViewDelegate> {
    Ref<Library>    _library;
    Ref<HTTPClient> _client;
    vector<Ref<Book> >  _books;
    GSBottomLoadingCell *_loadingCell;
    
    UISearchBar     *_searchBar;
    NSString        *_searchKey;
    int             _index;
    GSSearchResultView  *_searchTipsView;
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
    
    _searchTipsView = [[GSSearchResultView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.bounds.size.height + 60, bounds.size.width, 0)];
    _searchTipsView.clipsToBounds = YES;
    [_searchTipsView addTarget:self
                        action:@selector(closeInputMethod)
              forControlEvents:UIControlEventTouchUpInside];
    _searchTipsView.delegate = self;
    [self.view addSubview:_searchTipsView];
    
    _searchBar = [[UISearchBar alloc] init];
    _searchBar.frame = CGRectMake(0, self.navigationController.navigationBar.bounds.size.height + 20, bounds.size.width, 40);
    _searchBar.placeholder = local(Input key words here);
    _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _searchBar.delegate = self;
    _searchBar.showsScopeBar = YES;
    [self.view addSubview:_searchBar];
    
    _loadingCell = [[GSBottomLoadingCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:@"bottom_loading"];
    _loadingCell.status = GSBottomCellStatusWhite;
    
}

- (void)searchResultDidSelect:(NSString *)result {
    _searchBar.text = result;
    _searchKey = result;
    [_searchBar endEditing:YES];
    [self requestDatas];
    
}

- (void)closeInputMethod {
    [_searchBar endEditing:YES];
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

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    _searchTipsView.hidden = NO;
    CGRect bounds = self.view.bounds;
    [_searchTipsView setResults:SearchTip::search(searchBar.text.UTF8String)];
    [GTween cancel:_searchTipsView];
    GTween *tween = [GTween tween:_searchTipsView
                         duration:0.3
                             ease:[GEaseCubicIn class]];
    [tween addProperty:[GTweenCGRectProperty property:@"frame"
                                                 from:_searchTipsView.frame
                                                   to:CGRectMake(0, self.navigationController.navigationBar.bounds.size.height + 60, bounds.size.width, bounds.size.height - 40)]];
    [tween start];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    CGRect bounds = self.view.bounds;
    [GTween cancel:_searchTipsView];
    GTween *tween = [GTween tween:_searchTipsView
                         duration:0.3
                             ease:[GEaseCubicOut class]];
    [tween addProperty:[GTweenCGRectProperty property:@"frame"
                                                 from:_searchTipsView.frame
                                                   to:CGRectMake(0, self.navigationController.navigationBar.bounds.size.height + 60, bounds.size.width, 0)]];
    [tween.onComplete addBlock:^{
        _searchTipsView.hidden = YES;
    }];
    [tween start];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [_searchTipsView setResults:SearchTip::search(searchText.UTF8String)];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    _searchKey = searchBar.text;
    [_searchBar endEditing:YES];
    SearchTip::insert(_searchKey.UTF8String);
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
    Variant call(C([=](bool success, const Array &books, bool no_more){
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
        Variant call(C([=](bool success, const Array &books, bool no_more){
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
