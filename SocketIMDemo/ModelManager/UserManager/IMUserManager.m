//
//  UseManager.m
//  SocketIMDemo
//
//  Created by 李勇 on 18/3/15.
//  Copyright (c) 2018年李勇. All rights reserved.
//

#import "IMUserManager.h"

@interface IMUserManager () {
    /**realm数据库路径*/
    NSString *_pathUrl;
    /**主线程创建的realm数据库对象  用来创建数据观察者使用*/
    RLMRealm *_mainThreadRLMRealm;
    /**持有RLMNotificationToken对象，不然创建后就消失了*/
    NSMutableArray<RLMNotificationToken*> *_allNotificationTokenArr;
    
    /**让更新数据库的操作异步串行执行，降低cpu峰值*/
    NSOperationQueue *_operationQueue;
}

@end

@implementation IMUserManager

#pragma mark -- Init Methods

- (instancetype)init {
    self = [super init];
    if(!self) {
        return nil;
    }
    
    //得到用户对应的数据库路径
    NSArray<NSString*> *pathArr = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    _pathUrl = pathArr[0];
    //server是随便写的，因为服务器所有的数据都存在一个数据库
    _pathUrl = [_pathUrl stringByAppendingPathComponent:@"server"];
    //创建数据库
    _mainThreadRLMRealm = [RLMRealm realmWithURL:[NSURL URLWithString:_pathUrl]];
    //持有RLMNotificationToken对象
    _allNotificationTokenArr = [@[] mutableCopy];
    
    //让更新数据库的操作异步串行执行，降低cpu峰值
    _operationQueue = [NSOperationQueue new];
    _operationQueue.name = @"ImUserOperationQueue";
    _operationQueue.maxConcurrentOperationCount = 1;
    //优先级不用太高
    _operationQueue.qualityOfService = NSQualityOfServiceUtility;
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
    static IMUserManager *iMUserManager;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        iMUserManager = [IMUserManager new];
    });
    return iMUserManager;
}

#pragma mark - IMMsgContent

- (void)updateIMMsgContent:(IMMsgContent*)msgContent {
    [_operationQueue addOperationWithBlock:^{
        RLMRealm *rlmRealm = [self currThreadRealmInstance];
        [rlmRealm beginWriteTransaction];
        [IMMsgContent createOrUpdateInRealm:rlmRealm withValue:msgContent];
        [rlmRealm commitWriteTransaction];
    }];
}

- (IMMsgContent*)iMMsgContent:(int64_t)msgId {
    IMMsgContent *content = [IMMsgContent new];
    RLMRealm *rlmRealm = [self currThreadRealmInstance];
    RLMResults *results = [IMMsgContent objectsInRealm:rlmRealm withPredicate:[NSPredicate predicateWithFormat:@"msg_id = %@",@(msgId)]];
    if(results.count) {
        content = [[results objectAtIndex:0] deepCopy];
    }
    return content;
}

@end
