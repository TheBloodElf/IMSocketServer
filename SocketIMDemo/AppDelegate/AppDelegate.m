//
//  AppDelegate.m
//  SocketIMDemo
//
//  Created by 李勇 on 18/3/15.
//  Copyright (c) 2018年李勇. All rights reserved.
//

#import "AppDelegate.h"

//Tools
#import "IMSocketServer.h"

//Controllers
#import "ChatMineController.h"

@implementation AppDelegate 

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //启动聊天服务器
    [[IMSocketServer server] start];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[ChatMineController new]];
    navigationController.navigationBar.translucent = NO;
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
