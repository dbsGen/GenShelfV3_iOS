//
//  GSShopCell.h
//  GenS
//
//  Created by gen on 16/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSRadiusImageView.h"

@interface GSShopCell : UITableViewCell

@property (nonatomic, readonly) GSRadiusImageView *thumView;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, strong) NSString *content;

@property (nonatomic, strong) NSString *imageUrl;

@end
