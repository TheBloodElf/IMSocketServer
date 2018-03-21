//
//  NSString+isBlank.m
//  SocketIMDemo
//
//  Created by 李勇 on 18/3/15.
//  Copyright (c) 2018年李勇. All rights reserved.
//

#import "NSString+Category.h"

@implementation NSString (isBlank)

#pragma mark -- Init Methods

#pragma mark -- Class Private Methods

#pragma mark -- Class Public Methods

#pragma mark -- Function Private Methods

#pragma mark -- Function Public Methods

#pragma mark -- Instance Private Methods

#pragma mark -- Instance Public Methods

+ (BOOL)isBlank:(NSString*)str {
    //对象未初始化
    if (str == nil || str == NULL) {
        return YES;
    }
    //该对象属于NSNull族
    if ([str isKindOfClass:[NSNull class]]) {
        return YES;
    }
    //字符串全是空白
    if ([[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        return YES;
    }
    return NO;
}

@end
