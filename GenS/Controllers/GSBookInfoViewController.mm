//
//  GSBookInfoViewController.m
//  GenS
//
//  Created by mac on 2017/5/17.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSBookInfoViewController.h"
#include "../Common/Models/Book.h"
#include "../Common/Models/Chapter.h"
#import "GSRadiusImageView.h"
#import "MTPaddyButton.h"
#import "GSPartView.h"
#import "DIManager.h"
#import "MTNetCacheManager.h"
#import "GlobalsDefine.h"
#import "GTween.h"
#import "RKDropdownAlert.h"
#import "GSReadViewController.h"
#include <utils/network/HTTPClient.h>
#include "../Common/Models/Shop.h"
#import "GSChapterCell.h"

using namespace nl;
using namespace hirender;


@interface GSBookInfoViewController () <GSPartDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, DIItemDelegate, GSReadViewControllerDelegate> {
    Ref<Book> _book;
    GSRadiusImageView *_imageView;
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    
    UIButton *_closeButton;
    UIButton *_hostButton;
    UIButton *_collectButton;
    
    GSPartView *_partView;
    
    UICollectionView *_contentView;
    UIScrollView *_descriptionScrollView;
    UILabel *_descriptionLabel;
    
    vector<Ref<Chapter> > _chapters;
    
    NSString *_imageUrl;
    DIItem *_currentRequest;
    
    CGFloat _cellWidth;
    
    Ref<Library> _library;
    Ref<Shop> _shop;

    bool _hasMore;
    Ref<HTTPClient> _requreClient;
    int _index;
    
    BOOL _collectStatus;
}

@end

@implementation GSBookInfoViewController

- (id)initWithBook:(void *)b library:(void *)library shop:(void *)shop {
    self = [super init];
    if (self) {
        _book = (Book*)b;
        _library = (Library*)library;
        _shop = (Shop*)shop;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 120)];
    topView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    topView.layer.shadowColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1].CGColor;
    topView.layer.shadowOffset = CGSizeZero;
    topView.layer.shadowOpacity = 1;
    topView.layer.shadowRadius = 2;
    topView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:topView];
    
    
    _imageView = [[GSRadiusImageView alloc] initWithFrame:CGRectMake(10, 10, 60, 60)];
    _imageView.radius = 5;
    [topView addSubview:_imageView];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 10, self.view.bounds.size.width - 110, 36)];
    _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    _titleLabel.numberOfLines = 2;
    _titleLabel.font = [UIFont boldSystemFontOfSize:14];
    _titleLabel.textColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
    [topView addSubview:_titleLabel];
    
    _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 46, self.view.bounds.size.width - 110, 14)];
    _subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    _subtitleLabel.font = [UIFont systemFontOfSize:14];
    _subtitleLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1];
    [topView addSubview:_subtitleLabel];
    
    _hostButton = [[UIButton alloc] initWithFrame:CGRectMake(80, 10, self.view.bounds.size.width - 90, 60)];
    _hostButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_hostButton addTarget:self
                    action:@selector(gotoBook)
          forControlEvents:UIControlEventTouchUpInside];
    [_hostButton setBackgroundImage:[UIImage imageNamed:@"black"]
                           forState:UIControlStateHighlighted];
    _hostButton.layer.cornerRadius = 5;
    _hostButton.clipsToBounds = YES;
    _hostButton.alpha = 0.2;
    [topView addSubview:_hostButton];
    
    _closeButton = [[MTPaddyButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 44, 0, 44, 44)];
    [_closeButton setImage:[UIImage imageNamed:@"close"]
                  forState:UIControlStateNormal];
    _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    _closeButton.alpha = 0.6;
    [topView addSubview:_closeButton];
    
    [_closeButton addTarget:self
                     action:@selector(closeChecked)
           forControlEvents:UIControlEventTouchUpInside];
    _closeButton.layer.shadowColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1].CGColor;
    _closeButton.layer.shadowRadius = 1;
    _closeButton.layer.shadowOpacity = 1;
    _closeButton.layer.shadowOffset = CGSizeZero;
    
    _collectButton = [[MTPaddyButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 44, 44, 44, 44)];
    [_collectButton setImage:[UIImage imageNamed:@"heart"]
                  forState:UIControlStateNormal];
    _collectButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    _collectButton.alpha = 0.6;
    [topView addSubview:_collectButton];
    [_collectButton addTarget:self
                     action:@selector(collectClicked)
           forControlEvents:UIControlEventTouchUpInside];
    _collectButton.layer.shadowColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1].CGColor;
    _collectButton.layer.shadowRadius = 1;
    _collectButton.layer.shadowOpacity = 1;
    _collectButton.layer.shadowOffset = CGSizeZero;
    
    _partView = [[GSPartView alloc] initWithLabels:@[local(Content), local(Desc)]];
    _partView.frame = CGRectMake(0, 80, topView.bounds.size.width, 40);
    _partView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _partView.delegate = self;
    [topView addSubview:_partView];
    
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc]init];
    layout.minimumInteritemSpacing = 5;
    layout.minimumLineSpacing = 5;
    _contentView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 120, self.view.bounds.size.width,
                                                                        self.view.bounds.size.height - 120)
                    collectionViewLayout:layout];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    _contentView.delegate = self;
    _contentView.dataSource = self;
    _contentView.backgroundColor = [UIColor whiteColor];
    _contentView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [_contentView registerClass:[GSChapterCell class]
     forCellWithReuseIdentifier:@"normal"];
    [self.view insertSubview:_contentView belowSubview:topView];
    
    _descriptionScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width,
                                                                            120, self.view.bounds.size.width,
                                                                            self.view.bounds.size.height - 120)];
    _descriptionScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self.view insertSubview:_descriptionScrollView belowSubview:topView];
    
    _descriptionLabel = [[UILabel alloc] initWithFrame:CGRectInset(_descriptionScrollView.bounds, 10, 10)];
    _descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _descriptionLabel.font = [UIFont systemFontOfSize:14];
    _descriptionLabel.numberOfLines = 0;
    _descriptionLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
    [_descriptionScrollView addSubview:_descriptionLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    Variant v1(_book);
    _index = 0;
    Variant idx(_index);
    __weak GSBookInfoViewController *that = self;
    Variant v2(C([=](bool success, Ref<Book> book, RefArray chapters, bool hasMore){
        if (that) {
            GSBookInfoViewController *sthat = that;
            if (success) {
                book->setShopId(Shop::getCurrentShop()->getIdentifier());
                sthat->_book = book;
                [that updateBookInfo];
                sthat->_chapters.clear();
                for (int i = 0, t = (int)chapters.size(); i < t; ++i) {
                    Ref<Chapter> cp = chapters.at(i);
                    sthat->_chapters.push_back(cp);
                }
                sthat->_hasMore = hasMore;
                [_contentView reloadData];
            }else {
                [RKDropdownAlert title:local(Network error)
                       backgroundColor:RED_COLOR
                             textColor:[UIColor whiteColor]];
            }
            sthat->_requreClient = NULL;
        }
    }));
    pointer_vector vs{&v1, &idx, &v2};
    _requreClient = (Ref<HTTPClient>)_library->apply("loadBook", vs);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _cellWidth = (self.view.bounds.size.width - 40) / 3;
    _hostButton.frame = CGRectMake(80, 12, self.view.bounds.size.width - 90, 56);
    _titleLabel.frame = CGRectMake(80, 10, self.view.bounds.size.width - 110, 36);
    _subtitleLabel.frame = CGRectMake(80, 46, self.view.bounds.size.width - 110, 14);
    [self updateBookInfo];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_requreClient) {
        _requreClient->cancel();
    }
}

- (void)updateBookInfo {
    [self setDescription:[NSString stringWithUTF8String:_book->getDes().c_str()]];
    _titleLabel.text = [NSString stringWithUTF8String:_book->getName().c_str()];
    _subtitleLabel.text = [NSString stringWithUTF8String:_book->getSubtitle().c_str()];
    [self setImageUrl:[NSString stringWithUTF8String:_book->getThumb().c_str()]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)closeChecked {
    if (self.closeBlock) {
        self.closeBlock();
    }
}


- (void)collectClicked {
    _collectStatus = !_collectStatus;
    [_contentView reloadData];
}

- (void)partView:(GSPartView *)partView select:(NSInteger)index {
    if (index == 0) {
        [UIView animateWithDuration:0.4
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             _contentView.frame = CGRectMake(0, 120,
                                                             self.view.bounds.size.width,
                                                             self.view.bounds.size.height - 120);
                             _descriptionScrollView.frame = CGRectMake(self.view.bounds.size.width, 120,
                                                                       self.view.bounds.size.width,
                                                                       self.view.bounds.size.height - 120);
                         } completion:nil];
    }else {
        [UIView animateWithDuration:0.4
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             _contentView.frame = CGRectMake(-self.view.bounds.size.width, 120,
                                                             self.view.bounds.size.width,
                                                             self.view.bounds.size.height - 120);
                             _descriptionScrollView.frame = CGRectMake(0, 120,
                                                                       self.view.bounds.size.width,
                                                                       self.view.bounds.size.height - 120);
                         } completion:nil];
    }
}

- (void)setDescription:(NSString *)des {
    CGRect rect = CGRectInset(_descriptionScrollView.bounds, 10, 10);
    _descriptionLabel.text = des;
    rect.size = [_descriptionLabel sizeThatFits:CGSizeMake(rect.size.width, 9999)];
    _descriptionLabel.frame = rect;
    _descriptionScrollView.contentSize = rect.size;
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

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return (_chapters.size() && _hasMore) ? _chapters.size() + 1 : _chapters.size();
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GSChapterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"normal"
                                                                    forIndexPath:indexPath];
    if (_chapters.size() > indexPath.row) {
        cell.titleLabel.text = [NSString stringWithUTF8String:_chapters[indexPath.row]->getName().c_str()];
    }else {
        cell.titleLabel.text = local(More);
    }
    if (_collectStatus) {
        cell.color = BLUE_COLOR;
    }else {
        cell.color = GREEN_COLOR;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_collectStatus) {
        if (_chapters.size() > indexPath.row) {
            _shop->collect(*_book, *_chapters[indexPath.row]);
            [RKDropdownAlert title:local(Collect OK)
                   backgroundColor:BLUE_COLOR
                         textColor:[UIColor whiteColor]];
        }
    }else {
        if (_chapters.size() > indexPath.row) {
            if (self.pushController) {
                GSReadViewController *ctrl = [[GSReadViewController alloc] initWithChapter:*_chapters[indexPath.row]
                                                                                      shop:*_shop];
                ctrl.delegate = self;
                self.pushController([[UINavigationController alloc] initWithRootViewController:ctrl]);
            }
        }else {
            Variant v1(_book);
            Variant idx(++_index);
            __weak GSBookInfoViewController *that = self;
            Variant v2(C([=](bool success, Ref<Book> book, RefArray chapters, bool hasMore){
                if (that) {
                    GSBookInfoViewController *sthat = that;
                    if (success) {
                        sthat->_book = book;
                        [sthat updateBookInfo];
                        for (int i = 0, t = (int)chapters.size(); i < t; ++i) {
                            Ref<Chapter> cp = chapters.at(i);
                            sthat->_chapters.push_back(cp);
                        }
                        sthat->_hasMore = hasMore;
                        [_contentView reloadData];
                    }else {
                        [RKDropdownAlert title:local(Network error)
                               backgroundColor:RED_COLOR
                                     textColor:[UIColor whiteColor]];
                    }
                    sthat->_requreClient->cancel();
                    sthat->_requreClient = NULL;
                }
            }));
            pointer_vector vs{&v1, &idx, &v2};
            Ref<HTTPClient> client = _library->apply("loadBook", vs);
            _requreClient = client;
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return CGSizeMake(_cellWidth, 38);
}

- (void)gotoBook {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithUTF8String:_book->getUrl().c_str()]]];
}

- (void*)prevChapter:(void*)chapter {
    int i = (int)_chapters.size() - 1;
    for (; i >= 0; --i) {
        if (*_chapters[i] == chapter) {
            break;
        }
    }
    if (i != -1 && i < _chapters.size() - 1) {
        return *_chapters[i+1];
    }else {
        return NULL;
    }
}
- (void*)nextChapter:(void*)chapter {
    int i = (int)_chapters.size() - 1;
    for (; i >= 0; --i) {
        if (*_chapters[i] == chapter) {
            break;
        }
    }
    if (i != -1 && i > 0) {
        return *_chapters[i-1];
    }else {
        return NULL;
    }
}

- (void)collect:(void *)c {
    _shop->collect(*_book, (Chapter *)c);
}

@end
