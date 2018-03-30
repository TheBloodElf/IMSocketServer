//
//  ViewController.m
//  SocketIMDemo
//
//  Created by 李勇 on 18/3/15.
//  Copyright (c) 2018年李勇. All rights reserved.
//

#import "ChatMineController.h"

//Views
#import "ChatMineView.h"

//Managers
#import "ChatMineTableViewManager.h"
#import "IMUserManager.h"

@interface ChatMineController () {
    /**聊天数据管理器*/
    IMUserManager *_iMUserManager;
    
    /**表格视图管理者*/
    ChatMineTableViewManager *_tableViewManager;
}

@end

@implementation ChatMineController

#pragma mark -- Init Methods

- (instancetype)init {
    if(self = [super init]) {
        _iMUserManager = [IMUserManager manager];
    }
    return self;
}

#pragma mark -- Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"日志记录";
    self.view.backgroundColor = [UIColor whiteColor];
    //创建视图部分
    ChatMineView *chatMineView = [[ChatMineView alloc] initWithFrame:CGRectMake(0, 0, MAIN_SCREEN_WIDTH, MAIN_SCREEN_HEIGHT - 64)];
    [self.view addSubview:chatMineView];
    UITableView *tableView = [self.view viewWithTag:LOG_TABLE_VIEW_TAG];
    _tableViewManager = [[ChatMineTableViewManager alloc] initWithLogs:[_iMUserManager allServerLogs] tableView:tableView];
    tableView.delegate = _tableViewManager;
    tableView.dataSource = _tableViewManager;
    //实时监听日志表变化
    __weak typeof(self) weakSelf = self;
    [_iMUserManager addServerLogChangeListener:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf serverLogChange];
    }];
}

#pragma mark -- Function Methods

#pragma mark -- Private Methods

- (void)serverLogChange {
    [_tableViewManager updateLogs:[_iMUserManager allServerLogs]];
}


#pragma mark -- Public Methods

@end
