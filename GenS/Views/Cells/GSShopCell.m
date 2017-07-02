//
//  GSShopCell.m
//  GenS
//
//  Created by gen on 16/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import "GSShopCell.h"
#import "DIManager.h"
#import "MTNetCacheManager.h"

@interface GSShopCell () <DIItemDelegate>

@end

@implementation GSShopCell {
    DIItem *_currentRequest;
    UILabel *_contentLabel;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _thumView = [[GSRadiusImageView alloc] initWithFrame:CGRectMake(10, 10, 60, 60)];
        _thumView.radius = 5;
        _thumView.image = [UIImage imageNamed:@"no_image"];
        [self.contentView addSubview:_thumView];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 10, self.contentView.bounds.size.width - 90, 16)];
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        [self.contentView addSubview:_titleLabel];
        
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 30,
                                                                  self.contentView.bounds.size.width - 90,
                                                                  40)];
        _contentLabel.numberOfLines = 0;
        _contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _contentLabel.textColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1];
        _contentLabel.font = [UIFont systemFontOfSize:14];
        [self.contentView addSubview:_contentLabel];
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        [self performSelector:@selector(restore:)
                   withObject:[NSNumber numberWithBool:animated]
                   afterDelay:0];
    }
}

- (void)restore:(NSNumber*)animated {
    [self setSelected:NO animated:[animated boolValue]];
}

- (void)setImageUrl:(NSString *)imageUrl {
    if (_imageUrl != imageUrl) {
        if (_currentRequest) {
            [_currentRequest cancel];
            _currentRequest = NULL;
        }
        _thumView.image = [UIImage imageNamed:@"no_image"];
        _imageUrl = imageUrl;
        if (_imageUrl) {
            [[MTNetCacheManager defaultManager] getImageWithUrl:imageUrl
                                                          block:^(id result) {
                                                              if (result) {
                                                                  _thumView.image = result;
                                                              }else {
                                                                  _currentRequest = [[DIManager defaultManager] itemWithURLString:_imageUrl];
                                                                  _currentRequest.delegate = self;
                                                                  [_currentRequest start];
                                                              }
                                                          }];
        }
    }
}

- (void)itemComplete:(DIItem *)item {
    NSData *data = [NSData dataWithContentsOfFile:item.path];
    [[MTNetCacheManager defaultManager] setData:data
                                        withUrl:_imageUrl];
    _currentRequest = NULL;
    _thumView.image = [UIImage imageWithData:data];
}

- (void)setContent:(NSString *)content {
    _content = content;
    _contentLabel.text = content;
    CGRect rect = _contentLabel.frame;
    rect.size = [_contentLabel sizeThatFits:CGSizeMake(rect.size.width, 45)];
    rect.size.height = MIN(rect.size.height, 45);
    _contentLabel.frame = rect;
}

@end
