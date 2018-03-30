//
//  UseManager.m
//  SocketIMDemo
//
//  Created by 李勇 on 18/3/15.
//  Copyright (c) 2018年李勇. All rights reserved.
//

#import "IMUserManager.h"

/**UserManager单例对象*/
static IMUserManager *_userManagerInstance;

@interface IMUserManager () {
    /**realm数据库路径*/
    NSString *_pathUrl;
    /**主线程创建的realm数据库对象  用来创建数据观察者使用*/
    RLMRealm *_mainThreadRLMRealm;
    /**持有RLMNotificationToken对象，不然创建后就消失了*/
    NSMutableArray<RLMNotificationToken*> *_allNotificationTokenArr;
}

@end

@implementation IMUserManager

#pragma mark -- Init Methods

- (instancetype)init {
    self = [super init];
    if (self) {
        //得到用户对应的数据库路径
        NSArray *pathArr = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        _pathUrl = pathArr[0];
        //server是随便写的，因为服务器所有的数据都存在一个数据库
        _pathUrl = [_pathUrl stringByAppendingPathComponent:@"server"];
        //创建数据库
        _mainThreadRLMRealm = [RLMRealm realmWithURL:[NSURL URLWithString:_pathUrl]];
        //持有RLMNotificationToken对象
        _allNotificationTokenArr = [@[] mutableCopy];
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

- (void)updateIMMsgContent:(IMMsgContent*)msgContent {
    RLMRealm *rlmRealm = [self currThreadRealmInstance];
    [rlmRealm beginWriteTransaction];
    [IMMsgContent createOrUpdateInRealm:rlmRealm withValue:msgContent];
    [rlmRealm commitWriteTransaction];
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

- (void)updateServerLog:(IMServerLog*)serverLog {
    RLMRealm *rlmRealm = [self currThreadRealmInstance];
    [rlmRealm beginWriteTransaction];
    [IMServerLog createOrUpdateInRealm:rlmRealm withValue:serverLog];
    [rlmRealm commitWriteTransaction];
}

- (NSMutableArray<IMServerLog*>*)allServerLogs {
    NSMutableArray<IMServerLog*> *resultArr = [@[] mutableCopy];
    RLMRealm *rlmRealm = [self currThreadRealmInstance];
    RLMResults *results = [[IMServerLog objectsInRealm:rlmRealm withPredicate:nil] sortedResultsUsingKeyPath:@"id" ascending:NO];
    //依次填充所有的用户信息
    for (int index = 0; index < results.count; index ++) {
        //使用deepCopy拷贝一份数据
        [resultArr addObject:[results[index] deepCopy]];
    }
    return resultArr;
}

- (void)addServerLogChangeListener:(modelChangeHandler)changeHandler {
    RLMNotificationToken *notificationToken = [[IMServerLog allObjectsInRealm:_mainThreadRLMRealm] addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
        changeHandler();
    }];
    [_allNotificationTokenArr addObject:notificationToken];
}

@end
