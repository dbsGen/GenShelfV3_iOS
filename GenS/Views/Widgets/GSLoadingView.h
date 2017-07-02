//
//  GSLoadingView.h
//  GenS
//
//  Created by gen on 18/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GSLoadingView : UIView

- (UIButton*)button;

@property (nonatomic, readonly) BOOL display;

- (void)start;
- (void)stop;
- (void)failed;
- (void)miss;
- (void)message:(NSString *)label button:(NSString *)button;

@end
