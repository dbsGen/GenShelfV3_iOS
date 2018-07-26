//
//  GSShelfsViewController.h
//  GenS
//
//  Created by gen on 16/05/2017.
//  Copyright © 2017 gen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GSShelfsViewControllerDelegate <NSObject>

- (void)shelfBadgeChanged:(NSInteger)number;

@end

@interface GSShelfsViewController : UIViewController {
    
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, weak) id<GSShelfsViewControllerDelegate> delegate;

- (void)requestOnBegin;

@end
