//
//  UseManager.m
//  SocketIMDemo
//
//  Created by 李勇 on 18/3/15.
//  Copyright (c) 2018年李勇. All rights reserved.
//

#import "UserManager.h"

/**UserManager单例对象*/
static UserManager *_userManagerInstance;

@interface UserManager () {
    /**realm数据库路径*/
    NSString *_pathUrl;
    /**主线程创建的realm数据库对象  用来创建数据观察者使用*/
    RLMRealm *_mainThreadRLMRealm;
    /**增加一个操作队列，让数据库的操作顺序执行，这样可以避免inWriteTransaction问题*/
    NSOperationQueue *_dataOperationQueue;
}

@end

@implementation UserManager

#pragma mark -- Init Methods

- (instancetype)init {
    self = [super init];
    if (self) {
        //初始化数据库操作队列
        _dataOperationQueue = [NSOperationQueue new];
        //这里最大操作数设置为4个，因为是运行在子线程，每个子线程一个realm实例，所以不会出现inWriteTransaction错误
        _dataOperationQueue.maxConcurrentOperationCount = 4;
        _dataOperationQueue.name = @"RealmOperationQueue";
        //得到用户对应的数据库路径
        NSArray *pathArr = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        _pathUrl = pathArr[0];
        //server是随便写的，因为服务器所有的数据都存在一个数据库
        _pathUrl = [_pathUrl stringByAppendingPathComponent:@"server"];
    }
    return self;
}

#pragma mark -- Function Methods

#pragma mark -- Private Methods

/**
 获得当前调用方所在线程的realm数据库实例

 @return realm数据库实例
 */
- (RLMRealm*)currThreadRealmInstance {
    //得到数据库在当前线程中的实例
    RLMRealm *currRealm = [RLMRealm realmWithURL:[NSURL URLWithString:_pathUrl]];
    return currRealm;
}

#pragma mark -- Public Methods

+ (instancetype)manager {
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _userManagerInstance = [[self class] new];
    });
    return _userManagerInstance;
}

@end
