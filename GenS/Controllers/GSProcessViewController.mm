//
//  GSProcessViewController.m
//  GenS
//
//  Created by mac on 2017/9/3.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSProcessViewController.h"
#include "../Common/Models/Chapter.h"
#import "GSProcessCell.h"
#import "GlobalsDefine.h"

using namespace nl;

@interface GSProcessViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation GSProcessViewController {
    Array books;
    Array chapters;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setTitle:local(ProgressingC)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    books->clear();
    chapters->clear();
    
    Chapter::downloadingChapters(books, chapters);
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                              style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self.view addSubview:_tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return chapters->size();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"normal";
    GSProcessCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[GSProcessCell alloc] initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:identifier];
    }
    
    [cell setBook:books->get(indexPath.row)
          chapter:chapters->get(indexPath.row)];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52;
}

@end
