//
//  HEImageTexture.h
//  hirender_iOS
//
//  Created by gen on 16/11/2016.
//  Copyright © 2016 gen. All rights reserved.
//

#import "HETexture.h"

@protocol HEImageTexture <HETexture>

@property (nonatomic, strong) NSString *path;

@end

@interface HEImageTexture : HETexture <HEImageTexture>

@end
