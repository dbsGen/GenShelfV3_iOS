//
//  HETexture.h
//  hirender_iOS
//
//  Created by gen on 19/11/2016.
//  Copyright © 2016 gen. All rights reserved.
//

#import "HiObject.h"

@protocol HETexture <HiClass>

@property (nonatomic, assign) NSInteger channel;

- (NSInteger)getWidth;
- (NSInteger)getHeight;
- (void)render:(NSInteger)offx
              :(NSInteger)offy
              :(NSInteger)width
              :(NSInteger)height
              :(void*)buffer;
- (void)update;
- (void)clean;
- (void)reload;
- (BOOL)isFrameUpdate;
- (void)enableFrameUpdate:(BOOL)enable;
- (BOOL)isLoaded;

@end

@interface HETexture : HiObject <HETexture>

@end
