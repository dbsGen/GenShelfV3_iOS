//
//  GSPictureCell.h
//  GenS
//
//  Created by mac on 2017/6/24.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSDragView.h"
#import "GSMemCache.h"

@interface GSPictureCell : GSDragViewCell

@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) GSMemCache *memCache;

- (void)setPage:(void*)page;

@end
