//
//  ViewController.m
//  SocketIMDemo
//
//  Created by 李勇 on 18/3/15.
//  Copyright (c) 2018年李勇. All rights reserved.
//

#import "ViewController.h"

#import "IMSocketServer.h"

@interface ViewController () {
    /**聊天服务器对象*/
    IMSocketServer *_chatSocketServer;
}

@end

@implementation ViewController

#pragma mark -- Init Methods

#pragma mark -- Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化服务器
    _chatSocketServer = [IMSocketServer server];
}

#pragma mark -- Function Methods

#pragma mark -- Private Methods

- (IBAction)showConnectUserAndStatus:(id)sender {
    //拼接内容
    NSMutableString *contentString = [@"" mutableCopy];
    for (ChatSocketUser *socketUser in _chatSocketServer.allChatUsers) {
        if(socketUser.imid == 0) {
            continue;
        }
        [contentString appendFormat:@"用户："];
        [contentString appendString:@(socketUser.imid).stringValue];
        [contentString appendFormat:@"，状态："];
        if(socketUser.socketStatus == USER_SOCKET_STATUS_OFFLINE) {
            [contentString appendString:@"离线。\n"];
        }
        else {
            [contentString appendString:@"在线。\n"];
        }
    }
    
    //设置弹窗
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"连接用户以及状态" message:contentString preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:alertAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark -- Public Methods

@end
