//
//  GSTitleInnerButton.h
//  GenS
//
//  Created by mac on 2017/6/24.
//  Copyright © 2017年 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GSTitleInnerButton : UIButton {
    UIImageView         *_triView;
}

- (void)extend:(BOOL)ex;
- (void)updateTriPosition;

@end
