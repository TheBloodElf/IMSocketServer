//
//  UseManager.h
//  SocketIMDemo
//
//  Created by 李勇 on 18/3/15.
//  Copyright (c) 2018年李勇. All rights reserved.
//

/**
 数据库管理器，所有的数据操作通过本类完成
 */
@interface UserManager : NSObject

#pragma mark -- Function Methods

#pragma mark -- Private Methods

#pragma mark -- Public Methods

/**
 创建单例方法
 
 @return 单例对象
 */
+ (instancetype)manager;

@end
