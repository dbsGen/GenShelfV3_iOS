//
//  GSShelfViewController.m
//  GenShelf
//
//  Created by Gen on 16/2/19.
//  Copyright © 2016年 AirRaidClub. All rights reserved.
//

#import "GSShelfViewController.h"
#import "GSideMenuController.h"
#import "GSShopCell.h"
#import "GlobalsDefine.h"
#include "../Common/Models/Book.h"
#include "../Common/Models/Shop.h"
#import "GSLocalBookInfoViewController.h"
#import "GCoverView.h"
#include <utils/NotificationCenter.h>
#import "GSLoadingView.h"
#import "GSHomeController.h"
#import "GSWidgetButton.h"
#import "GSProcessViewController.h"
#import "GSUtils.hpp"

static BOOL _shelf_reload = YES;

using namespace nl;

@interface GSShelfViewController ()<UITableViewDelegate, UITableViewDataSource> {
    UIBarButtonItem *_editItem, *_doneItem;
    CGFloat _oldPosx;
    
    vector<Ref<Book> > _books;
    RefCallback message_listener;
    GSLoadingView *_loadingView;
    
    GSWidgetButton *_widgetButton;
}

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation GSShelfViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = local(Shelf);
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"]
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(openMenu)];
        _editItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                  target:self
                                                                  action:@selector(editBooks)];
        _doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                  target:self
                                                                  action:@selector(editDone)];
        self.navigationItem.rightBarButtonItem = _editItem;
        
        message_listener = C([=](){
            _shelf_reload = YES;
        });
        gr::NotificationCenter::getInstance()->listen(Shop::NOTIFICATION_COLLECTED, message_listener);
        
        _shelf_reload = YES;
    }
    return self;
}

- (void)dealloc {
    gr::NotificationCenter::getInstance()->remove(Shop::NOTIFICATION_COLLECTED, message_listener);
}

- (void)removeData:(NSNotification *)notification {
//    if ([_datas containsObject:notification.object]) {
//        NSInteger index = [_datas indexOfObject:notification.object];
//        [_datas removeObjectAtIndex:index];
//        [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index
//                                                                inSection:0]]
//                          withRowAnimation:UITableViewRowAnimationAutomatic];
//    }
}

+ (void)setReloadCache:(BOOL)reload {
    _shelf_reload = reload;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_shelf_reload) {
        _books.clear();
        const map<string, Ref<Book> > &local_books = Book::getLocalBooks();
        for (auto it = local_books.begin(), _e = local_books.end(); it != _e; ++it) {
            _books.push_back(it->second);
        }
        struct BookCompare {
            bool operator ()(const Ref<Book> &b1, const Ref<Book> &b2) {
                return b1->getIndex() > b2->getIndex();
            }
        };
        sort(_books.begin(), _books.end(), BookCompare());
        
        [_tableView reloadData];
        if (_books.size() != 0) {
            _loadingView.hidden = YES;
        }else {
            _loadingView.hidden = NO;
            _loadingView.tag = 1;
            [_loadingView message:local(Empty collect one)
                           button:local(go)];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                              style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth| UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_tableView];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(onPan:)];
    [self.view addGestureRecognizer:pan];
    
    _loadingView = [[GSLoadingView alloc] initWithFrame:self.view.bounds];
    [_loadingView.button addTarget:self
                            action:@selector(buttonClicked)
                  forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_loadingView];
    
    CGRect bounds = self.view.bounds;
    _widgetButton = [[GSWidgetButton alloc] initWithFrame:CGRectMake(bounds.size.width - 88, bounds.size.height-88, 48, 48)];
    _widgetButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [_widgetButton setIconImage:[UIImage imageNamed:@"download"]];
    [self.view addSubview:_widgetButton];
    [_widgetButton addTarget:self
                      action:@selector(gotoDownload)
            forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)openMenu {
    [self.sideMenuController openMenu];
}

- (void)editBooks {
    [_tableView setEditing:YES animated:YES];
    self.navigationItem.rightBarButtonItem = _doneItem;
}

- (void)editDone {
    [_tableView setEditing:NO animated:YES];
    self.navigationItem.rightBarButtonItem = _editItem;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _books.size();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"NormalCell";
    GSShopCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[GSShopCell alloc] initWithStyle:UITableViewCellStyleDefault
                                 reuseIdentifier:identifier];
    }
    const Ref<Book> &book = _books[indexPath.row];
    cell.titleLabel.text = [NSString stringWithUTF8String:book->getName().c_str()];
    [cell setImageUrl:[NSString stringWithUTF8String:book->getThumb().c_str()]
              headers:dic(book->getThumbHeaders())];
    cell.content = [NSString stringWithUTF8String:book->getSubtitle().c_str()];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    GSLocalBookInfoViewController *ctrl = [[GSLocalBookInfoViewController alloc] initWithBook:*_books[indexPath.row]];
    GCoverView *cover = [[GCoverView alloc] initWithController:ctrl];
    __weak GCoverView *_cover = cover;
    ctrl.closeBlock = ^() {
        [_cover miss];
    };
    __weak GSShelfViewController *that = self;
    ctrl.pushController = ^(UIViewController *c) {
        [that.sideMenuController presentViewController:c animated:YES
                                            completion:nil];
    };
    ctrl.allRemoved = ^() {
        [_cover miss];
        [that removeAt:indexPath];
    };
    [cover showInView:self.sideMenuController.view];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete:
        {
            [self removeAt:indexPath];
        }
            break;
            
        default:
            break;
    }
}

- (void)removeAt:(NSIndexPath *)indexPath {
    auto it = _books.begin() + indexPath.row;
    Ref<Book> book = *it;
    _books.erase(it);
    book->removeBook();
    [_tableView deleteRowsAtIndexPaths:@[indexPath]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    _loadingView.hidden = _books.size() != 0;
}

- (void)onPan:(UIPanGestureRecognizer*)pan {
    switch (pan.state) {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self.sideMenuController touchEnd];
            break;
        case UIGestureRecognizerStateBegan:
            _oldPosx = [pan translationInView:pan.view].x;
            break;
        default: {
            CGFloat newPosx = [pan translationInView:pan.view].x;
            [self.sideMenuController touchMove:newPosx-_oldPosx];
            _oldPosx = newPosx;
        }
            break;
    }
}

- (void)buttonClicked {
    [GSHomeController setNevIndex:1];
}

- (void)gotoDownload {
    [self.navigationController pushViewController:[[GSProcessViewController alloc] init]
                                         animated:YES];
}

@end
