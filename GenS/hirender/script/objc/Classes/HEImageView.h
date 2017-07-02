//
//  HEImageView.h
//  hirender_iOS
//
//  Created by gen on 16/11/2016.
//  Copyright © 2016 gen. All rights reserved.
//

#import "HEView.h"

@protocol HEImageView <HEView>

@property (nonatomic, strong) id texture;

@end

@interface HEImageView : HEView <HEImageView>

@end
