//
//  GSLocalBookInfoViewController.m
//  GenS
//
//  Created by mac on 2017/5/20.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSLocalBookInfoViewController.h"
#include "../Common/Models/Book.h"
#include "../Common/Models/Shop.h"
#import "GSPartView.h"
#import "GSRadiusImageView.h"
#import "DIManager.h"
#import "MTPaddyButton.h"
#import "GlobalsDefine.h"
#import "GSChapterCell.h"
#import "MTNetCacheManager.h"
#import "GSReadViewController.h"
#import "MTAlertView.h"
#import "GSReadViewController.h"

using namespace nl;
using namespace gcore;

@interface GSLocalBookInfoViewController () <GSPartDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, DIItemDelegate, MTAlertViewDelegate, GSReadViewControllerDelegate>

@property (nonatomic, assign) BOOL edit;

@end

@implementation GSLocalBookInfoViewController {
    Ref<Book> _book;
    GSRadiusImageView *_imageView;
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    
    UIButton *_closeButton;
    UIButton *_hostButton;
    UIButton *_editButton;
    
    GSPartView *_partView;
    
    UICollectionView *_contentView;
    UIScrollView *_descriptionScrollView;
    UILabel *_descriptionLabel;
    
    vector<Ref<Chapter> > _chapters;
    
    NSString *_imageUrl;
    DIItem *_currentRequest;
    
    CGFloat _cellWidth;
    
    NSIndexPath *_currentIndex;
}

- (id)initWithBook:(void *)book {
    self = [super init];
    if (self) {
        _book = (Book*)book;
        
        auto &chapters = _book->getChapters();
        for (auto it = chapters->begin(), _e = chapters->end(); it != _e; ++it) {
            _chapters.push_back(it->second);
        }
        
        struct ChapterCompare {
            bool operator()(const Ref<Chapter> &c1, const Ref<Chapter> &c2) {
                return c1->getName().compare(c2->getName()) > 0;
            }
        };
        sort(_chapters.begin(), _chapters.end(), ChapterCompare());
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
    
    _editButton = [[MTPaddyButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 44, 44, 44, 44)];
    [_editButton setImage:[UIImage imageNamed:@"edit"]
                 forState:UIControlStateNormal];
    _editButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    _editButton.alpha = 0.6;
    [topView addSubview:_editButton];
    [_editButton addTarget:self
                    action:@selector(editChecked)
          forControlEvents:UIControlEventTouchUpInside];
    _editButton.layer.shadowColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1].CGColor;
    _editButton.layer.shadowRadius = 1;
    _editButton.layer.shadowOpacity = 1;
    _editButton.layer.shadowOffset = CGSizeZero;
    
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _cellWidth = (self.view.bounds.size.width - 40) / 3;
    _hostButton.frame = CGRectMake(80, 12, self.view.bounds.size.width - 90, 56);
    _titleLabel.frame = CGRectMake(80, 10, self.view.bounds.size.width - 110, 36);
    _subtitleLabel.frame = CGRectMake(80, 46, self.view.bounds.size.width - 110, 14);
    [self updateBookInfo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateBookInfo {
    [self setDescription:[NSString stringWithUTF8String:_book->getDes().c_str()]];
    _titleLabel.text = [NSString stringWithUTF8String:_book->getName().c_str()];
    _subtitleLabel.text = [NSString stringWithUTF8String:_book->getSubtitle().c_str()];
    [self setImageUrl:[NSString stringWithUTF8String:_book->getThumb().c_str()]];
}

- (void)closeChecked {
    if (self.closeBlock) {
        self.closeBlock();
    }
}

- (void)editChecked {
    self.edit = !self.edit;
}

- (void)setEdit:(BOOL)edit {
    if (_edit != edit) {
        _edit = edit;
        [_contentView reloadData];
    }
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
    return _chapters.size();
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GSChapterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"normal"
                                                                    forIndexPath:indexPath];
    cell.titleLabel.text = [NSString stringWithUTF8String:_chapters[indexPath.row]->getName().c_str()];
    cell.color = _edit ? RED_COLOR : GREEN_COLOR;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//    if (self.pushController) {
//        GSReadViewController *ctrl = [[GSReadViewController alloc] initWithChapter:*_chapters[indexPath.row]
//                                                                              shop:*_shop];
//        ctrl.delegate = self;
//        self.pushController(ctrl);
//    }
    if (self.edit) {
        _currentIndex = indexPath;
        Ref<Chapter> chapter = _chapters[indexPath.row];
        MTAlertView *alert = [[MTAlertView alloc] initWithTitle:local(Will remove)
                                                        content:[NSString stringWithUTF8String:chapter->getName().c_str()]
                                                          image:nil
                                                        buttons:local(YES), local(NO), nil];
        alert.delegate = self;
        [alert show];
    }else {
        GSReadViewController *ctrl = [[GSReadViewController alloc] initWithChapter:*_chapters[indexPath.row]
                                                                              shop:*Shop::find(_book->getShopId())
                                                                              book:*_book];
        ctrl.delegate = self;
        if (self.pushController) {
            self.pushController([[UINavigationController alloc] initWithRootViewController:ctrl]);
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

- (void)alertView:(MTAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
    if (index == 0) {
        auto it = _chapters.begin() + _currentIndex.row;
        _book->removeChapter(**it);
        _chapters.erase(it);
        [_contentView deleteItemsAtIndexPaths:@[_currentIndex]];
        if (_chapters.size() == 0) {
            if (self.allRemoved) {
                self.allRemoved();
            }
        }
    }
}

@end
