//
//  AppDelegate.m
//  SocketIMDemo
//
//  Created by 李勇 on 18/3/15.
//  Copyright (c) 2018年李勇. All rights reserved.
//

#import "AppDelegate.h"
#import "ChatSocketServer.h"

@implementation AppDelegate 

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //启动聊天服务器
    [[ChatSocketServer server] start];
    return YES;
}

@end
