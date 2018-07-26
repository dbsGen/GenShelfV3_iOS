//
//  GSReadViewController.m
//  GenS
//
//  Created by gen on 18/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import "GSReadViewController.h"
#include "../Common/Models/Chapter.h"
#include "../Common/Models/Book.h"
#include "../Common/Models/Shop.h"
#import "RKDropdownAlert.h"
#import "GlobalsDefine.h"
#import "JGActionSheet.h"
#import "GSLoadingView.h"
#import "DIManager.h"
#import "GSDownloadManager.h"
#import "RKDropdownAlert.h"
#import "DownloadQueue.h"
#import "GSDragView.h"
#import "GSPictureCell.h"
#import "GSTitleInnerButton.h"
#import "GSCoverSelectView.h"
#include <utils/NotificationCenter.h>
#include <zconf.h>

using namespace nl;
using namespace gcore;
using namespace gr;

@interface GSReadViewController ()  <DIItemDelegate, GSDragViewDelegate, GSCoverSelectViewDelegate> {
    Ref<Chapter>    _chapter;
    Ref<Reader>     _reader;
    Ref<Shop>       _shop;
    Ref<Book>       _book;
    NSInteger       _oldIndex;
    GSLoadingView   *_loadingView;
    NSInteger       _oldRowCount;
    pointer_map     _itemIndexes;
    
    NSMutableArray  *_requestItems;
    int prev_status;
    int next_status;
    
    vector<Ref<Page> >  _pages;
    RefCallback _onPageStatus;
    RefCallback _onChapterPercent;
    RefCallback _onChapterPageCount;
    RefCallback _onChapterStatus;
    
    Ref<HTTPClient> _reloadClient;
    UIView  *_processBar;
    GSTitleInnerButton  *_titleButton;
    GSMemCache  *_memCache;
}

@property (nonatomic, strong) GSDragView *dragView;

@end

@implementation GSReadViewController

- (id)initWithChapter:(void*)chapter shop:(void*)shop book:(void*)book {
    self = [super init];
    if (self) {
        _chapter = (Chapter*)chapter;
        _shop = (Shop*)shop;
        self.title = [NSString stringWithUTF8String:_chapter->getName().c_str()];
        _oldIndex = 0;
        _requestItems = [NSMutableArray array];
        _book = (Book*)book;
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:local(Back)
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(backClicked)];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"]
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(moreClicked)];
        _memCache = [[GSMemCache alloc] init];
        
    }
    return self;
}

- (id)initWithChapter:(void *)chapter shop:(void *)shop {
    self = [self initWithChapter:chapter shop:shop book:nil];
    if (self) {
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_book) {
        if (_chapter->getPages().size() != 0) {
            [_loadingView stop];
            _loadingView.hidden = YES;
            [_dragView reloadData];
        }
        [self setupLocalBook];
    }else
        [self setupReader];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[GSDownloadManager defaultManager] removeItems:_requestItems];
}

- (void)setupReader {
    if (!_reader) {
        prev_status = 0;
        next_status = 0;
        _reader = new_t(Reader);
        __weak GSReadViewController *that = self;
        _reader->setOnPageCount(C([=](bool success, int count){
            if (that) {
                GSReadViewController *sthat = that;
                if (success)  {
                    _pages.resize(count);
                    [sthat updateTitle];
                    if (sthat->_loadingView.display) {
                        [sthat.dragView reloadData];
                        sthat.dragView.pageIndex = 0;
                        [sthat displayReader];
                    }else {
                        [sthat.dragView reloadCount];
                    }
                }else {
                    [RKDropdownAlert title:local(Network error)
                           backgroundColor:RED_COLOR
                                 textColor:[UIColor whiteColor]];
                }
            }
        }));
        _reader->setOnPageLoaded(C([=](bool success, int idx, Ref<Page> page){
            if (that) {
                GSReadViewController *sthat = that;
                if (success) {
                    if (sthat->_pages.size() <= idx) {
                        sthat->_pages.resize(idx + 1);
                        [sthat updateTitle];
                    }
                    sthat->_pages[idx] = page;
                    if (sthat->_pages.size() > 3) {
                        if (sthat->_loadingView.display) {
                            [sthat.dragView reloadData];
                            sthat.dragView.pageIndex = 0;
                            [sthat displayReader];
                        }else {
                            [sthat.dragView reloadCount];
                        }
                    }
                    GSPictureCell *cell = (GSPictureCell *)[_dragView cellAtIndex:idx];
                    if (cell) {
                        [cell setPage:*page];
                    }
                }
            }
        }));
        _shop->setupReader(*_reader);
        Variant vcha(_chapter);
        pointer_vector vs{&vcha};
        _reader->apply("process", vs);
    }
}

- (void)setupLocalBook {
    if (_chapter->downloadStatus() == DownloadQueue::StatusComplete) {
        _processBar.hidden = YES;
    }else {
        _processBar.hidden = NO;
        _processBar.alpha = 1;
        _processBar.frame = CGRectMake(0, 0, self.view.bounds.size.width * 0.00f, 4);
    }
    
    _pages.clear();
    const Array &ps = _chapter->getPages();
    if (ps.size() != 0) {
        for (long i = 0, t = ps.size(); i < t; ++i) {
            _pages.push_back(ps->get(i));
        }
        [_dragView reloadData];
    }
    
    __weak GSReadViewController *that = self;
    _onPageStatus = C([=](Page *page, Ref<Chapter> chapter, int index, int status) {
        if (that) {
            GSReadViewController *sthat = that;
            if (sthat->_chapter == chapter && status == DownloadQueue::StatusComplete) {
                BOOL size_changed = false;
                auto &pages = sthat->_pages;
                while (pages.size() <= index) {
                    pages.push_back(NULL);
                    size_changed = true;
                }
                pages[index] = page;
                
                if (sthat->_loadingView.display) {
                    [sthat displayReader];
                    [sthat.dragView reloadData];
                }else {
                    GSPictureCell *view = (GSPictureCell*)[sthat.dragView cellAtIndex:index];
                    string path = sthat->_book->picturePath(*sthat->_chapter, (int)index);
                    NSString *imagePath = [NSString stringWithUTF8String:path.c_str()];
                    if (view) {
                        if (access(path.c_str(), F_OK) == 0) {
                            [view setImage:[UIImage imageWithContentsOfFile:imagePath]];
                        }else {
                            [view setImage:[UIImage imageNamed:@"no_image"]];
                        }
                    }
                    [sthat.dragView reloadCount];
                }
            }
        }
    });
    NotificationCenter::getInstance()->listen(DownloadPage::NOTIFICATION_STATUS, _onPageStatus);
    
    _onChapterPercent = C([=](const Ref<Chapter> &chapter, float percent){
        if (that) {
            GSReadViewController *sthat = that;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 sthat->_processBar.frame = CGRectMake(0, 0, self.view.bounds.size.width * percent, 4);
                             } completion:^(BOOL finished) {
                             }];
            sthat->_processBar.hidden = NO;
        }
    });
    NotificationCenter::getInstance()->listen(DownloadChapter::NOTIFICATION_PERCENT, _onChapterPercent);
    
    if (Shop::download(*_book, *_chapter) == 2) {
        [RKDropdownAlert title:[NSString stringWithFormat:@"<%s> is not installed.", _book->getShopId().str()]
               backgroundColor:RED_COLOR textColor:[UIColor whiteColor]];
    }
    
    _onChapterStatus = C([=](const Ref<Chapter> &chapter, int status){
        if (that) {
            GSReadViewController *sthat = that;
            if (status == DownloadQueue::StatusComplete) {
                [UIView animateWithDuration:0.1
                                 animations:^{
                                     sthat->_processBar.alpha = 0;
                                 } completion:^(BOOL finished) {
                                     sthat->_processBar.hidden = YES;
                                 }];
            }
        }
    });
    NotificationCenter::getInstance()->listen(DownloadChapter::NOTIFICATION_STATUS, _onChapterStatus);
    
    if (ps.size() == 0) {
        int size = _chapter->oldDownloaded();
        if (size > 0)  {
            while (_pages.size() < size) {
                _pages.push_back(NULL);
            }
            [_dragView reloadData];
            [self displayReader];
        }
        _onChapterPageCount = C([=](const Ref<Chapter> &chapter, int page_count){
            if (that) {
                GSReadViewController *sthat = that;
                if (sthat->_chapter == chapter) {
                    while (sthat->_pages.size() < page_count) {
                        sthat->_pages.push_back(NULL);
                    }
                    [sthat displayReader];
                    [sthat.dragView reloadData];
                }
            }
        });
        NotificationCenter::getInstance()->listen(DownloadChapter::NOTIFICATION_PAGE_COUNT, _onChapterPageCount);
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_reader) {
        _reader->apply("stop");
    }
    if (_onPageStatus) {
        NotificationCenter::getInstance()->remove(DownloadPage::NOTIFICATION_STATUS, _onPageStatus);
        _onPageStatus = NULL;
    }
    if (_onChapterPercent) {
        NotificationCenter::getInstance()->remove(DownloadChapter::NOTIFICATION_PERCENT, _onChapterPercent);
        _onChapterPercent = NULL;
    }
    if (_onChapterPageCount) {
        NotificationCenter::getInstance()->remove(DownloadChapter::NOTIFICATION_PAGE_COUNT, _onChapterPageCount);
        _onChapterPageCount = NULL;
    }
    if (_onChapterStatus) {
        NotificationCenter::getInstance()->remove(DownloadChapter::NOTIFICATION_STATUS, _onChapterStatus);
        _onChapterStatus = NULL;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_pages.size()) {
        [self displayReader];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _dragView = [[GSDragView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width,
                                                             self.view.bounds.size.height)];
    _dragView.delegate = self;
    _dragView.backgroundColor = [UIColor blackColor];
//    _dragView.bottomLabel.text = local(Next chapter);
//    _dragView.topLabel.text = local(Prev chapter);
    _dragView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    _dragView.dragable = _pageViewer;
//    [_dragView reloadData];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(onTap)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [_dragView addGestureRecognizer:tap];
    [self.view addSubview:_dragView];
    
    _loadingView = [[GSLoadingView alloc] initWithFrame:self.view.bounds];
    [_loadingView start];
    [self.view addSubview:_loadingView];
    
    _processBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 4,
                                                           self.view.bounds.size.width * 1, 4)];
    _processBar.hidden = YES;
    _processBar.backgroundColor = BLUE_COLOR;
    _processBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_processBar];
    
    
    GSTitleInnerButton *button = [[GSTitleInnerButton alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    NSString *string = [NSString stringWithUTF8String:_chapter->getName().c_str()];
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
               action:@selector(titleClicked)
     forControlEvents:UIControlEventTouchUpInside];
    
    _titleButton = button;
    self.navigationItem.titleView = _titleButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)displayReader {
    if (_loadingView.display) {
        [_loadingView miss];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        _dragView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
}

- (GSDragViewCell *)dragView:(GSDragView *)dragView atIndex:(NSInteger)index{
    GSPictureCell *cell = (GSPictureCell*)[dragView dequeueCell];
    if (!cell) {
        cell = [[GSPictureCell alloc] initWithFrame:dragView.bounds];
        cell.memCache = _memCache;
    }
    if (_book) {
        string path = _book->picturePath(*_chapter, (int)index);
        if (access(path.c_str(), F_OK) == 0) {
            cell.imagePath = [NSString stringWithUTF8String:path.c_str()];
        }else {
            cell.image = [UIImage imageNamed:@"no_image"];
        }
    }else {
        if (_pages.size() <= index) {
            cell.image = [UIImage imageNamed:@"no_image"];
        }else {
            const Ref<Page> &page = _pages[index];
            if (!page || page->getPicture().empty()) {
                cell.image = [UIImage imageNamed:@"no_image"];
            }else {
                [cell setPage:*page];
            }
        }
    }
    return cell;
}

- (NSInteger)dragViewCellCount:(GSDragView *)dragView {
    return _pages.size();
}

- (void)dragView:(GSDragView *)dragView page:(NSInteger)index {
    [self updateTitle];
}

- (void)backClicked {
    if (_reader) {
        _reader->setOnPageCount(NULL);
        _reader->setOnPageLoaded(NULL);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)moreClicked {
    NSMutableArray *buttons = [NSMutableArray array];
    [buttons addObject:local(Collect)];
    [buttons addObject:local(Refresh)];
    JGActionSheetSection *section1 = [JGActionSheetSection sectionWithTitle:local(Picture Options)
                                                                    message:nil
                                                               buttonTitles:buttons
                                                                buttonStyle:JGActionSheetButtonStyleBlue];
    JGActionSheetSection *cancelSection = [JGActionSheetSection sectionWithTitle:nil
                                                                         message:nil
                                                                    buttonTitles:@[local(Close)]
                                                                     buttonStyle:JGActionSheetButtonStyleCancel];
    JGActionSheet *sheet = [JGActionSheet actionSheetWithSections:@[section1, cancelSection]];
    
    [sheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
        [sheet dismissAnimated:YES];
        NSString *str = [buttons objectAtIndex:indexPath.row];
        if ([str isEqualToString:local(Collect)]) {
            [self.delegate collect:*_chapter];
        }else if ([str isEqualToString:local(Refresh)]) {
            [self reloadPage:_dragView.pageIndex];
        }
//        if ([str isEqualToString:local(Mark page to reload)]) {
//            [_item.pages objectAtIndex:_flipView.pageIndex].pageStatus = GSPageStatusNotStart;
//        }else if ([str isEqualToString:local(Download)]) {
//            [GSGlobals downloadBook:_item];
//        }else if ([str isEqualToString:local(Pause)]) {
//            [[GSGlobals getDataControl:_item.source] pauseBook:_item];
//        }else if ([str isEqualToString:local(Reload pages)]) {
//            [_item fullyCheckStatues];
//            [GSGlobals downloadBook:_item];
//        }else if ([str isEqualToString:local(Reload list)]) {
//            [_item reset];
//            [GSGlobals downloadBook:_item];
//        }
        sheet.buttonPressedBlock = nil;
    }];
    
    [sheet showInView:self.view animated:YES];
}


- (void)requireUrl:(NSString *)url index:(NSInteger)index {
    DIItem *item = [[DIManager defaultManager] itemWithURLString:url];
    item.delegate = self;
    [item start];
}

- (void)itemComplete:(DIItem *)item {
    auto it = _itemIndexes.find((__bridge void*)item);
    if (it != _itemIndexes.end()) {
        long idx = (long)it->second;
        GSPictureCell *cell = (GSPictureCell*)[_dragView cellAtIndex:idx];
        cell.imagePath = item.path;
        [_requestItems removeObject:item];
    }
}

- (void)itemFailed:(DIItem *)item error:(NSError *)error {
    
}

- (void)reloadChapter:(Chapter*)chapter {
    if (_reader) {
        _reader->apply("stop");
        _reader = NULL;
    }
    _chapter = chapter;
    [[GSDownloadManager defaultManager] removeItems:_requestItems];
    _loadingView.hidden = NO;
    [_loadingView start];
    [self.navigationController setNavigationBarHidden:NO
                                             animated:YES];
    [UIView animateWithDuration:0.3
                     animations:^{
                         _loadingView.alpha = 1;
                     }];
    [_dragView reloadData];
    [self setupReader];
}

- (void)reloadPage:(NSInteger)index {
    Ref<Page> page;
    if (_reader) {
        page = (Ref<Page>)_reader->getPages()->at(index);
    }else {
        page = _pages[index];
    }
    
    if (!_reader) {
        if (_shop) {
            _reader = new_t(Reader);
            _shop->setupReader(*_reader);
        }else {
        }
    }
    if (_reader) {
        GSPictureCell *cell = (GSPictureCell*)[_dragView cellAtIndex:index];
        UIImage *image = [UIImage imageNamed:@"no_image"];
        cell.image = image;
        
        Variant vpage(page);
        Variant idx(index);
        Variant on_complete(C([=](bool success, const Ref<Page> &page){
            _reloadClient = page->makeClient();
            _reloadClient->setReadCache(false);
            _reloadClient->setRetryCount(3);
            _reloadClient->setOnComplete(C([=](const Ref<HTTPClient> client){
                GSPictureCell *cell = (GSPictureCell*)[_dragView cellAtIndex:index];
                NSString *path = [NSString stringWithUTF8String:client->getPath().c_str()];
                cell.imagePath = path;
            }));
            _reloadClient->start();
        }));
        pointer_vector vs{&vpage, &idx, &on_complete};
        _reader->apply("reloadPage", vs);
    }
}

- (void)titleClicked {
    if (!_loadingView.hidden) {
        return;
    }
    CGRect rect = self.view.bounds;
    GSCoverSelectView *coverView = [[GSCoverSelectView alloc] initWithFrame:CGRectMake((rect.size.width - 160)/2, 56, 160, 200)];
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 0, t = _pages.size(); i < t; ++i) {
        [arr addObject:[NSString stringWithFormat:local(Page N), i]];
    }
    coverView.params = arr;
    coverView.selected = _dragView.pageIndex;
    coverView.delegate = self;
    [coverView show];
    [_titleButton extend:YES];
}

- (void)updateTitle {
    NSString *title = [NSString stringWithUTF8String:_chapter->getName().c_str()];
    if (title.length > 6)
        title = [title substringToIndex:6];
    title = [title stringByAppendingFormat:@"(%d/%lu)", _dragView.pageIndex + 1, _pages.size()];
    
    [_titleButton setTitle:title
                  forState:UIControlStateNormal];
    [_titleButton updateTriPosition];
}

- (void)coverSelectViewMiss:(GSCoverSelectView *)view {
    [_titleButton extend:NO];
}

- (void)coverSelectView:(GSCoverSelectView *)view selected:(NSInteger)index {
    [_dragView setPageIndex:index animate:YES];
    [view miss];
}

- (void)onTap {
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden
                                             animated:YES];
}

- (void)dragView:(GSDragView *)dragView chapter:(BOOL)next {
    if (next) {
        Chapter *chapter = (Chapter *)[self.delegate nextChapter:*_chapter];
        if (chapter) {
            [self reloadChapter:chapter];
        }else {
            [RKDropdownAlert title:local(No next)
                   backgroundColor:BLUE_COLOR
                         textColor:[UIColor whiteColor]];
        }
    }else {
        Chapter *chapter = (Chapter *)[self.delegate prevChapter:*_chapter];
        if (chapter) {
            [self reloadChapter:chapter];
        }else {
            [RKDropdownAlert title:local(No prev)
                   backgroundColor:BLUE_COLOR
                         textColor:[UIColor whiteColor]];
        }
    }
}

@end
