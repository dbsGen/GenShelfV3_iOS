//
//  GSSettingViewController.m
//  GenS
//
//  Created by mac on 2017/5/16.
//  Copyright © 2017年 gen. All rights reserved.
//

#import "GSSettingViewController.h"
#include "../Common/Models/Shop.h"
#include "../Common/Models/Settings.h"
#import "GSSwitchCell.h"
#import "GSSelectCell.h"
#import "GSInputCell.h"
#import "GlobalsDefine.h"
#import "GSLibraryViewController.h"
#import "GSHomeController.h"

using namespace hicore;
using namespace nl;

int indexOfItem(const vector<Ref<SettingItem> > &items, const Ref<SettingItem> &item) {
    for (int i = items.size() - 1; i >= 0; --i) {
        if (items[i] == item) {
            return i;
        }
    }
    return -1;
}

@interface GSSettingItem : NSObject {
    @public
    vector<Ref<SettingItem> > _items;
}

@property (nonatomic, strong) NSString *name;

@end

@implementation GSSettingItem

@end

@interface GSSettingViewController () <UITableViewDelegate, UITableViewDataSource, GSSelectCellDelegate, UITextFieldDelegate> {
    Ref<Shop> _shop;
    
    NSMutableArray *_settingSections;
    Ref<Settings> _settings;
    
}

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation GSSettingViewController

- (id)initWithShop:(void *)shop {
    self =  [super init];
    if (self) {
        _shop = (Shop*)shop;
        const Ref<Settings> &settings = _shop->getSettings();
        _settings = settings;
        GSSettingItem *currentItem = [[GSSettingItem alloc] init];
        _settingSections = [NSMutableArray array];
        [_settingSections addObject:currentItem];
        for (int i = 0, t = settings->getItemsCount(); i < t; ++i) {
            const Ref<SettingItem> &item = settings->getItem(i);
            if (item->getType() == SettingItem::Divider) {
                if (_settingSections.count == 1 && currentItem.name == nil && currentItem->_items.size() == 0) {
                    currentItem.name = [NSString stringWithUTF8String:item->getName().c_str()];
                }else {
                    currentItem = [[GSSettingItem alloc] init];
                    [_settingSections addObject:currentItem];
                }
            }else {
                currentItem->_items.push_back(item);
            }
        }
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:local(Back)
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(backClicked)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home"]
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(homeClicked)];
        
        self.title = [NSString stringWithUTF8String:_shop->getName().c_str()];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                              style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _settingSections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    GSSettingItem *item = [_settingSections objectAtIndex:section];
    return item.name;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    GSSettingItem *item = [_settingSections objectAtIndex:section];
    return item->_items.size();
}

- (NSString *)str:(const char *)chs {
    return chs ? [NSString stringWithUTF8String:chs] : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GSSettingItem *item = [_settingSections objectAtIndex:indexPath.section];
    const Ref<SettingItem> &setting_item = item->_items[indexPath.row];
    switch (setting_item->getType()) {
        case SettingItem::Mark:
        {
            static NSString *identifier = @"CheckCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:identifier];
            }
            cell.textLabel.text = [self str:setting_item->getName().c_str()];
            cell.textLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
            cell.accessoryType = (bool)setting_item->getValue() ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            return cell;
        }
        case SettingItem::Switch: {
            static NSString *identifier = @"SwitchCell";
            GSSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (!cell) {
                cell = [[GSSwitchCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:identifier];
                [cell.switchItem addTarget:self
                                    action:@selector(onSettingSwitch:)
                          forControlEvents:UIControlEventValueChanged];
            }
            cell.textLabel.text = [self str:setting_item->getName().c_str()];
            cell.textLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
            cell.switchItem.on = (bool)setting_item->getValue();
            cell.switchItem.tag = indexOfItem(_settings->getItems(), setting_item);
            return cell;
        }
            
        case SettingItem::Option: {
            static NSString *identifier = @"OptionsCell";
            GSSelectCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (!cell) {
                cell = [[GSSelectCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:identifier];
                cell.delegate = self;
            }
            NSInteger selectIndex = (int)setting_item->getValue();
            cell.opetionSelected = selectIndex;
            RefArray options(setting_item->getParams());
            if (options) {
                NSMutableArray *arr = [NSMutableArray array];
                for (int i = 0, t = (int)options->size(); i < t; ++i) {
                    [arr addObject:[self str:options.at(i)]];
                }
                cell.options = arr;
            }else {
                cell.options = @[@"Unkown"];
            }
            cell.contentLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
            cell.textLabel.text = [self str:setting_item->getName().c_str()];
            cell.textLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
            cell.tag = indexOfItem(_settings->getItems(), setting_item);
            return cell;
        }
            break;
        case SettingItem::Input:
        case SettingItem::Password: {
            static NSString *identifier = @"InputCell";
            GSInputCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            if (!cell) {
                cell = [[GSInputCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:identifier];
            }
            cell.textLabel.text = [self str:setting_item->getName().c_str()];
            cell.textLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
            cell.inputView.textColor = [UIColor colorWithWhite:0.6 alpha:1];
            cell.inputView.placeholder = [self str:setting_item->getDefaultValue()];
            if ((void*)setting_item->getValue() != (void*)setting_item->getDefaultValue())
                cell.inputView.text = [self str:setting_item->getValue()];
            cell.inputView.secureTextEntry = setting_item->getType() == SettingItem::Password;
            cell.inputView.delegate = self;
            cell.inputView.tag = indexOfItem(_settings->getItems(), setting_item);
            cell.inputView.returnKeyType = UIReturnKeyDone;
            return cell;
        }
            
        default:
            break;
    }
    return NULL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    GSSettingItem *item = [_settingSections objectAtIndex:indexPath.section];
    const Ref<SettingItem> &setting_item = item->_items[indexPath.row];
    switch (setting_item->getType()) {
        case SettingItem::Option: {
            GSSelectCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            GSSelectView *pickerView = [cell makePickView];
            [self.view addSubview:pickerView];
            [pickerView show];
            [self.view endEditing:YES];
            break;
        }
        case SettingItem::Mark: {
            setting_item->setValue(!setting_item->getValue());
            [tableView reloadRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            _settings->save();
            if (_shop == Shop::getCurrentShop()) {
                [GSLibraryViewController setReloadCache:YES];
            }
            break;
        }
        default:
            break;
    }
}

- (void)onSettingSwitch:(UISwitch *)sw {
    NSInteger tag = sw.tag;
    if (tag >= 0) {
        const Ref<SettingItem> &item = _settings->getItem(tag);
        item->setValue(sw.on);
        _settings->save();
        if (_shop == Shop::getCurrentShop()) {
            [GSLibraryViewController setReloadCache:YES];
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSInteger tag = textField.tag;
    if (tag >= 0) {
        const Ref<SettingItem> &item = _settings->getItem(tag);
        item->setValue(textField.text.UTF8String);
        _settings->save();
        if (_shop == Shop::getCurrentShop()) {
            [GSLibraryViewController setReloadCache:YES];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField endEditing:YES];
    return YES;
}

- (void)selectCellChanged:(GSSelectCell *)cell {
    NSInteger tag = cell.tag;
    if (tag >= 0) {
        const Ref<SettingItem> &item = _settings->getItem(tag);
        item->setValue(cell.opetionSelected);
        _settings->save();
        if (_shop == Shop::getCurrentShop()) {
            [GSLibraryViewController setReloadCache:YES];
        }
    }
}

- (void)backClicked {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)homeClicked {
    Shop::setCurrentShop(_shop);
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [GSHomeController setNevIndex:1];
    if (self.closeCoverBlock) {
        self.closeCoverBlock();
    }
}

@end
