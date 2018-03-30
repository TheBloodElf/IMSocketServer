//
//  IMClientLog.m
//  IMServer
//
//  Created by Mac on 2018/3/30.
//  Copyright © 2018年 Mac. All rights reserved.
//

#import "IMServerLog.h"

@implementation IMServerLog

MJExtensionCodingImplementation

#pragma mark -- Init Methods

#pragma mark -- Function Methods

#pragma mark -- Private Methods

+ (NSString*)primaryKey {
    return @"id";
}

#pragma mark -- Public Methods

+ (instancetype)clientLogWithMessage:(NSString*)message {
    IMServerLog *serverLog = [IMServerLog new];
    serverLog.id = [NSDate new].timeIntervalSince1970 * 1000;
    serverLog.message = message;
    serverLog.date = [NSDate new];
    return serverLog;
}

@end
