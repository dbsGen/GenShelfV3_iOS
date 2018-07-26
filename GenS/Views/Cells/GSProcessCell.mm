//
//  GSProcessCell.m
//  GenS
//
//  Created by mac on 2017/9/3.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSProcessCell.h"
#import "Book.h"
#import "Chapter.h"
#import "DownloadQueue.h"
#import "GlobalsDefine.h"
#import "NotificationCenter.h"

using namespace nl;

@interface GSProcessCell ()

@property (nonatomic, assign) Ref<Book> book;
@property (nonatomic, assign) Ref<Chapter> chapter;
@property (nonatomic, assign) int total;
@property (nonatomic, assign) int completed;
@property (nonatomic, assign) DownloadQueue::Status status;

@end

@implementation GSProcessCell {
    
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    UIView *_contrainerBar;
    UIView *_processBar;
    
    UIButton *_actionButton;
    
    RefCallback _percentCallback;
    RefCallback _statusCallback;
    RefCallback _totalCallback;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        CGRect bounds = self.contentView.bounds;
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, bounds.size.width - 60, 20)];
        _titleLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _titleLabel.font = [UIFont systemFontOfSize:14];
        [self.contentView addSubview:_titleLabel];
        
        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 23, bounds.size.width - 60, 20)];
        _subtitleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        _subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _subtitleLabel.font = [UIFont systemFontOfSize:12];
        [self.contentView addSubview:_subtitleLabel];
        
        _contrainerBar = [[UIView alloc] initWithFrame:CGRectMake(10, bounds.size.height - 5, bounds.size.width - 20, 5)];
        _contrainerBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_contrainerBar];
        
        _processBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 5)];
        _processBar.backgroundColor = BLUE_COLOR;
        [_contrainerBar addSubview:_processBar];
        
        _actionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 38, 38)];
        _actionButton.hidden = YES;
        _actionButton.center = CGPointMake(bounds.size.width - 29, bounds.size.height/2);
        _actionButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_actionButton addTarget:self
                          action:@selector(actionClicked)
                forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_actionButton];
        
        __weak GSProcessCell *that = self;
        _percentCallback = C([=](const Ref<Chapter> &chapter, float per) {
            if (chapter && chapter == that.chapter) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [that updatePercent:per];
                });
            }
        });
        NotificationCenter::getInstance()->listen(DownloadChapter::NOTIFICATION_PERCENT, _percentCallback);
        
        _statusCallback = C([=](const Ref<Chapter> &chapter, DownloadQueue::Status status){
            if (chapter && chapter == that.chapter) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    that.status = status;
                    [that updateStatus:status];
                });
            }
        });
        NotificationCenter::getInstance()->listen(DownloadChapter::NOTIFICATION_STATUS, _statusCallback);
        
        _totalCallback = C([=](const Ref<Chapter> &chapter, int total, int completed){
            if (chapter && chapter == that.chapter) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    that.total = total;
                    that.completed = completed;
                    [that updateStatus:that.status];
                });
            }
        });
        NotificationCenter::getInstance()->listen(DownloadChapter::NOTIFICATION_PAGE_COUNT, _totalCallback);
    }
    return self;
}

- (void)dealloc {
    NotificationCenter::getInstance()->remove(DownloadChapter::NOTIFICATION_PERCENT, _percentCallback);
    NotificationCenter::getInstance()->remove(DownloadChapter::NOTIFICATION_STATUS, _statusCallback);
    NotificationCenter::getInstance()->remove(DownloadChapter::NOTIFICATION_PAGE_COUNT, _totalCallback);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    
}

- (void)setBook:(void *)book chapter:(void *)chapter {
    _book = (Book*)book;
    _chapter = (Chapter*)chapter;
    
    _total = _chapter->pageCount();
    _completed = _chapter->completeCount();
    
    _titleLabel.text = [NSString stringWithUTF8String:_book->getName().c_str()];
    _subtitleLabel.text = [NSString stringWithUTF8String:_chapter->getName().c_str()];
    _status = _chapter->downloadStatus();
    
    [self updatePercent];
    [self updateStatus:_status];
}


- (void)updatePercent {
    [self updatePercent:_chapter->downloadPercent()];
}
- (void)updatePercent:(float)per {
    _processBar.frame = CGRectMake(0, 0, _contrainerBar.bounds.size.width * per,
                                   _contrainerBar.bounds.size.height);
}

- (void)updateStatus:(int)status {
    string title = _chapter->getName() + " (";
    switch (_status) {
        case 5: {
            title += "Waiting...";
            [_actionButton setImage:[UIImage imageNamed:@"pause"]
                           forState:UIControlStateNormal];
            _actionButton.hidden = NO;
            break;
        }
        case 1: {
            title += "Loading...";
            [_actionButton setImage:[UIImage imageNamed:@"pause"]
                           forState:UIControlStateNormal];
            _actionButton.hidden = NO;
            break;
        }
        case 2: {
            title += "Completed";
            _actionButton.hidden = YES;
            break;
        }
        case 3: {
            title += "Paused";
            [_actionButton setImage:[UIImage imageNamed:@"play"]
                           forState:UIControlStateNormal];
            _actionButton.hidden = NO;
            break;
        }
        case 4: {
            title += "Failed";
            [_actionButton setImage:[UIImage imageNamed:@"play"]
                           forState:UIControlStateNormal];
            _actionButton.hidden = NO;
            break;
        }
        default: {
            title += "Unkown";
            [_actionButton setImage:[UIImage imageNamed:@"play"]
                           forState:UIControlStateNormal];
            _actionButton.hidden = NO;
        }
    }
    if (_total > 0) {
        title += " ";
        char str[20];
        sprintf(str, "%d/%d", _completed, _total);
        title += str;
    }
    title += ')';
    _subtitleLabel.text = [NSString stringWithUTF8String:title.c_str()];
}

- (void)actionClicked {
    int status = _chapter->downloadStatus();
    if (status == DownloadQueue::StatusLoading || status == DownloadQueue::StatusWaiting) {
        _chapter->stopDownload();
    }else {
        Shop::download(*_book, *_chapter);
    }
}

@end
