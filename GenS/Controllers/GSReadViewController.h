//
//  GSReadViewController.h
//  GenS
//
//  Created by gen on 18/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GSReadViewControllerDelegate <NSObject>

- (void*)prevChapter:(void*)chapter;
- (void*)nextChapter:(void*)chapter;

- (void)collect:(void *)chapter;

@end

@interface GSReadViewController : UIViewController

@property (nonatomic, weak) id<GSReadViewControllerDelegate> delegate;

- (id)initWithChapter:(void*)chapter shop:(void*)shop;
- (id)initWithChapter:(void*)chapter shop:(void*)shop book:(void*)book;

@end
