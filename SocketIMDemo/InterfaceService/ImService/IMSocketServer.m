//
//  IMSocketServer.m
//  SocketIMDemo
//
//  Created by 李勇 on 18/3/15.
//  Copyright (c) 2018年李勇. All rights reserved.
//

#import "IMSocketServer.h"

//Models
#import "IMSocketHeader.h"
#import "IMProtocolClientReq.h"
#import "IMProtocolServerResp.h"

//SocketHandlers
#import "IMSocketUserHandler.h"

/**读取数据超时时间*/
#define DF_SOCKET_READ_TIMEOUT      -1
/**写入数据超时时间*/
#define DF_SOCKET_WRITE_TIMEOUT     -1

@implementation ChatSocketUser

- (instancetype)init {
    self = [super init];
    if (self) {
        _imid = 0;
        _socketStatus = USER_SOCKET_STATUS_OFFLINE;
        _mutableData = [NSMutableData new];
    }
    return self;
}

@end

@interface IMSocketServer ()<GCDAsyncSocketDelegate> {
    /**用于监听客户端连接的socket*/
    GCDAsyncSocket *_gCDAsyncSocket;
    
    /**检测心跳的定时器*/
    NSTimer *_heartbeatTimer;
}

@end

@implementation IMSocketServer

/**IMSocketServer单例对象*/
static IMSocketServer * _socketServerInstance;

#pragma mark -- Init Methods

- (id)init {
    if (self = [super init]) {
        _allChatUsers = [@[] mutableCopy];
        //在子线程监听客户端连接
        _gCDAsyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    }
    return self;
}

#pragma mark -- Function Methods

#pragma mark -- Private Methods

/**
 不断的检测是否有用户已离线
 */
- (void)handleTimeOutTimer {
    @synchronized(self) {
        //现在的时间
        int64_t nowTime = [[NSDate date] timeIntervalSince1970] * 1000;
        for (ChatSocketUser *socketModel in _allChatUsers) {
            //如果用户已经处于离线状态，就不进行处理了
            if(socketModel.socketStatus == USER_SOCKET_STATUS_OFFLINE) {
                continue;
            }
            //得到该用户最后一次发送心跳的时间
            int64_t currModelLastHeartTime = socketModel.lastHeartTime;
            //超过5s则设置为离线状态
            if(nowTime - 5000 > currModelLastHeartTime) {
                socketModel.socketStatus = USER_SOCKET_STATUS_OFFLINE;
            }
        }
    }
}

/**
 发送数据
 @param socketUser 哪个人
 @param data 包内容
 @param type 包类型
 */
- (void)socketUser:(ChatSocketUser*)socketUser sendData:(NSData *)data headerType:(E_SOCKET_HEADER_CMD_TYPE)type {
    //创建一个消息头部
    IMSocketHeader *header = [[IMSocketHeader alloc] init];
    header.body_len = data ? (int)data.length : 0;
    //设置消息类型 握手、登录、退出、被踢下线、公告
    header.command = type;
    NSData *headerData = [header getHeaderData];
    NSMutableData *send_data = [headerData mutableCopy];
    //如果有发送的数据，就把数据加到头部后面
    if (data) {
        [send_data appendData:data];
    }
    //发送封装好的数据
    [socketUser.gCDAsyncSocket writeData:send_data withTimeout:DF_SOCKET_WRITE_TIMEOUT tag:0];
    [socketUser.gCDAsyncSocket readDataWithTimeout:DF_SOCKET_READ_TIMEOUT tag:0];
}

/**
 让某个人处理当前收到的部分数据
 
 @param socketUser 哪个人
 @param data 收到了部分数据
 */
- (void)socketUser:(ChatSocketUser*)socketUser handleReceivedData:(NSData *)data {
    //加一个原子操作，保证这部分数据分析完成再分析下一部分数据
    @synchronized(self) {
        [socketUser.mutableData appendData:data];
        [self tryParseReceivedData:socketUser];
    }
}

/**
 找到该GCDAsyncSocket对象对应的ChatSocketUser对象，肯定是存在的，因为didReadData在didAcceptNewSocket之后执行
 
 @param socket GCDAsyncSocket对象
 @return ChatSocketUser对象
 */
- (ChatSocketUser*)socketUserWithAsyncSocket:(GCDAsyncSocket*)socket {
    ChatSocketUser *socketUser = nil;
    for (ChatSocketUser *tempSocket in _allChatUsers) {
        if(tempSocket.gCDAsyncSocket == socket) {
            socketUser = tempSocket;
            break;
        }
    }
    return socketUser;
}

/**
 找到该imid对应的ChatSocketUser对象，如果没有则返回nil
 
 @param imid imid
 @return ChatSocketUser对象
 */
- (ChatSocketUser*)socketUserWithImid:(int64_t)imid {
    ChatSocketUser *socketUser = nil;
    for (ChatSocketUser *tempSocket in _allChatUsers) {
        if(tempSocket.imid == imid) {
            socketUser = tempSocket;
            break;
        }
    }
    return socketUser;
}

/**
 试着解析数据 这里面处理了、分包、粘包、错误包的情况
 
 @param socketUser 哪个人
 */
- (void)tryParseReceivedData:(ChatSocketUser*)socketUser {
    //头部都没有获取完，不解析 说明还没有获取到有body的部分
    if ([socketUser.mutableData length] < DF_SOCKET_HEADER_LENGTH) {
        return;
    }
    //提取 包头部
    IMSocketHeader *header = [[IMSocketHeader alloc] init];
    NSData *headerData = [socketUser.mutableData subdataWithRange:NSMakeRange(0, DF_SOCKET_HEADER_LENGTH)];
    [header setProperty:headerData];
    // 校验数据 如果数据校验没有通过，就去掉这部分数据
    if (header.magic_num != DF_SOCKET_HEADER_MAGIC_NUM) {
        [socketUser.mutableData setData:[NSData data]];
        return;
    }
    //头部指出了body的长度，如果现在接收的不完整，就不处理  分包情况
    if (header.body_len > ([socketUser.mutableData length] - DF_SOCKET_HEADER_LENGTH)) {
        return;
    }
    //当前数据池有一整个body数据
    NSData *dataBody = [socketUser.mutableData subdataWithRange:NSMakeRange(DF_SOCKET_HEADER_LENGTH, header.body_len)];
    //收到了一个完整的数据
    [self socketUser:socketUser didReceiveWithHeader:header bodyData:dataBody];
    //如果数据中有超过一个完整包的部分，去除头与body，保留剩余部分，再次解析 粘包
    if ([socketUser.mutableData length] - DF_SOCKET_HEADER_LENGTH - header.body_len > 0) {
        NSInteger loc = DF_SOCKET_HEADER_LENGTH + header.body_len;
        NSInteger len = [socketUser.mutableData length] - loc;
        [socketUser.mutableData setData:[socketUser.mutableData subdataWithRange:NSMakeRange(loc, len)]];
        [self tryParseReceivedData:socketUser];
    }
    else {//出现错误，去掉这部分数据
        [socketUser.mutableData setData:[NSData data]];
    }
}

/**
 对要发送的数据进行加解密

 @param socketUser 用户
 @param data 要发送的数据
 */
- (void)socketUser:(ChatSocketUser*)socketUser encryptData:(NSData*)data {
    char *crptyData = (char *)[data bytes];
    for(int i = 0; i< [data length]; i++) {
        *crptyData = (*crptyData)^socketUser.cryptKey;
        crptyData++;
    }
}

/**
 收到了一个完整的数据包
 
 @param socketUser 哪个人
 @param header 包头部
 @param bodyData 包体
 */
- (void)socketUser:(ChatSocketUser*)socketUser didReceiveWithHeader:(IMSocketHeader *)header bodyData:(NSData *)bodyData {
    //如果是握手消息
    if(header.command == E_SOCKET_HEADER_CMD_HANDSHAKE) {
        [self socketUser:socketUser handleHandShakeHeader:header bodyData:bodyData];
    }
    //如果是公共消息
    if(header.command == E_SOCKET_HEADER_CMD_COMMON) {
        [self socketUser:socketUser handleCommonHeader:header bodyData:bodyData];
    }
    //如果是心跳消息
    if(header.command == E_SOCKET_HEADER_CMD_KEEPALIVE) {
        [self socketUser:socketUser handleKeepaliveHeader:header bodyData:bodyData];
    }
    //如果是登录
    if(header.command == E_SOCKET_HEADER_CMD_LOGIN) {
        [self socketUser:socketUser handleLoginHeader:header bodyData:bodyData];
    }
    //如果是退出消息
    if(header.command == E_SOCKET_HEADER_CMD_LOGOUT) {
        [self socketUser:socketUser handleLogoutHeader:header bodyData:bodyData];
    }
}

/**
 处理握手消息

 @param socketUser 哪个人
 @param header 包头
 @param bodyData 包体
 */
- (void)socketUser:(ChatSocketUser*)socketUser handleHandShakeHeader:(IMSocketHeader *)header bodyData:(NSData *)bodyData {
    //随机获取一个加密字符
    NSString *cryptKey = @((int64_t)[NSDate new].timeIntervalSince1970 % 10).stringValue;
    NSData *cryptKeyData = [cryptKey dataUsingEncoding:NSUTF8StringEncoding];
    char cryptChar;
    [cryptKeyData getBytes:&cryptChar length:1];
    //给该用户设置加密字符
    socketUser.cryptKey = cryptChar;
    //握手消息，加上该用户对应的加密字符返回
    [self socketUser:socketUser sendData:cryptKeyData headerType:E_SOCKET_HEADER_CMD_HANDSHAKE];
}

/**
 处理公共消息
 
 @param socketUser 哪个人
 @param header 包头
 @param bodyData 包体
 */
- (void)socketUser:(ChatSocketUser*)socketUser handleCommonHeader:(IMSocketHeader *)header bodyData:(NSData *)bodyData {
    
}

/**
 处理登录消息
 
 @param socketUser 哪个人
 @param header 包头
 @param bodyData 包体
 */
- (void)socketUser:(ChatSocketUser*)socketUser handleLoginHeader:(IMSocketHeader *)header bodyData:(NSData *)bodyData {
    //加解密
    [self socketUser:socketUser encryptData:bodyData];
    //把用户发来的数据转成IMProtocolClientReq对象
    IMProtocolClientReq *protocolClientReq = [IMProtocolClientReq new];
    NSString *clientReqString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
    [protocolClientReq mj_setKeyValues:[clientReqString mj_keyValues]];
    //我们需要取出该用户的登录信息
    UserLoginReq *loginReq = [UserLoginReq new];
    [loginReq mj_setKeyValues:[protocolClientReq.body mj_keyValues]];
    //判断登录信息是否正确 各项信息是否都有
    if([NSString isBlank:loginReq.username] ||
       [NSString isBlank:loginReq.device_token] ||
       [NSString isBlank:loginReq.client_version] ||
       ![loginReq.passwd isEqualToString:@"bb_password"]) {
        //向该用户发送错误信息
        IMProtocolServerResp *serverResp = [IMProtocolServerResp new];
        serverResp.seq = protocolClientReq.seq;
        serverResp.type = PACK_TYPE_RESP;
        //设置为登录信息错误
        serverResp.code = E_SOCKET_ERROR_LOGIN_INFO_ERROR;
        serverResp.cmd = protocolClientReq.cmd;
        serverResp.sub_cmd = protocolClientReq.sub_cmd;
        //错误不需要设置内容
        serverResp.body = nil;
        //转换成data
        NSData *serverRespData = [serverResp.mj_keyValues.mj_JSONString dataUsingEncoding:NSUTF8StringEncoding];
        //加解密
        [self socketUser:socketUser encryptData:serverRespData];
        //发送数据
        [self socketUser:socketUser sendData:serverRespData headerType:E_SOCKET_HEADER_CMD_COMMON];
        return;
    }
    
    //各项信息都是正确的，判断该用户是否已经存在
    int64_t currUserImid = loginReq.username.longLongValue;
    ChatSocketUser *oldSocketUser = [self socketUserWithImid:currUserImid];
    //如果用户已经存在，就通知旧用户被踢下线
    if(oldSocketUser != nil) {
        //向该用户发送被踢下线通知
        IMProtocolServerResp *serverResp = [IMProtocolServerResp new];
        serverResp.seq = protocolClientReq.seq;
        serverResp.type = PACK_TYPE_RESP;
        serverResp.code = E_SOCKET_ERROR_NONE;
        serverResp.cmd = protocolClientReq.cmd;
        //被踢下线的sub_cmd
        serverResp.sub_cmd = @"kickout";
        UserKickoutNotify *kickoutNotify = [UserKickoutNotify new];
        //被踢下线
        kickoutNotify.reason = 1;
        kickoutNotify.from_source_type = protocolClientReq.source_type;
        serverResp.body = kickoutNotify.mj_keyValues.mj_JSONString;
        //转换成data
        NSData *serverRespData = [serverResp.mj_keyValues.mj_JSONString dataUsingEncoding:NSUTF8StringEncoding];
        //加解密
        [self socketUser:socketUser encryptData:serverRespData];
        //发送数据
        [self socketUser:socketUser sendData:serverRespData headerType:E_SOCKET_HEADER_CMD_COMMON];
        //设置离线状态，并且不再处理数据 相当于是收到退出登录请求一样
        socketUser.socketStatus = USER_SOCKET_STATUS_OFFLINE;
        //断开连接
        [socketUser.gCDAsyncSocket disconnect];
    }
    
    //设置该用户最新的信息
    socketUser.imid = currUserImid;
    socketUser.lastHeartTime = [NSDate new].timeIntervalSince1970 * 1000;
    socketUser.socketStatus = USER_SOCKET_STATUS_ONLINE;
    //给该用户发送登录成功的信息
    IMProtocolServerResp *serverResp = [IMProtocolServerResp new];
    serverResp.seq = protocolClientReq.seq;
    serverResp.type = PACK_TYPE_RESP;
    serverResp.code = E_SOCKET_ERROR_NONE;
    serverResp.cmd = protocolClientReq.cmd;
    serverResp.sub_cmd = protocolClientReq.sub_cmd;
    //登录成功
    UserLoginResp *loginResp = [UserLoginResp new];
    loginResp.imid = currUserImid;
    serverResp.body = loginResp.mj_keyValues.mj_JSONString;
    //转换成data
    NSData *serverRespData = [serverResp.mj_keyValues.mj_JSONString dataUsingEncoding:NSUTF8StringEncoding];
    //加解密
    [self socketUser:socketUser encryptData:serverRespData];
    //发送数据
    [self socketUser:socketUser sendData:serverRespData headerType:E_SOCKET_HEADER_CMD_COMMON];
}

/**
 处理退出消息
 
 @param socketUser 哪个人
 @param header 包头
 @param bodyData 包体
 */
- (void)socketUser:(ChatSocketUser*)socketUser handleLogoutHeader:(IMSocketHeader *)header bodyData:(NSData *)bodyData {
    //设置离线
    socketUser.socketStatus = USER_SOCKET_STATUS_OFFLINE;
    //断开连接
    [socketUser.gCDAsyncSocket disconnect];
}

/**
 处理心跳消息
 
 @param socketUser 哪个人
 @param header 包头
 @param bodyData 包体
 */
- (void)socketUser:(ChatSocketUser*)socketUser handleKeepaliveHeader:(IMSocketHeader *)header bodyData:(NSData *)bodyData {
    //如果用户从离线变为在线，需要主动发送离线给该用户，如用户从后台变为前台，网络从不可用变成可用等情况
    if(socketUser.socketStatus == USER_SOCKET_STATUS_OFFLINE) {
        //获取离线消息发送给该用户
    }
    //设置用户在线
    socketUser.socketStatus = USER_SOCKET_STATUS_ONLINE;
    //设置心跳时间为现在的时间
    socketUser.lastHeartTime = [NSDate new].timeIntervalSince1970 * 1000;
}

#pragma mark -- Public Methods

+ (instancetype)server {
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _socketServerInstance = [[self class] new];
    });
    return _socketServerInstance;
}

- (void)start {
    //开始监听
    [_gCDAsyncSocket acceptOnPort:6868 error:nil];
    //不断的检测用户是否已经离线
    _heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(handleTimeOutTimer) userInfo:nil repeats:YES];
}

#pragma makr -- GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    //一个设备，建立多个连接，那么newSocket也会是不一样的，所以_allChatUsers中不会有两个一样的socket对象
    //添加一个到数组中
    ChatSocketUser *socketUser = [ChatSocketUser new];
    socketUser.gCDAsyncSocket = newSocket;
    [_allChatUsers addObject:socketUser];
    //继续接收数据
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    //继续接收数据
    [sock readDataWithTimeout:-1 tag:0];
    //处理数据
    [self socketUser:[self socketUserWithAsyncSocket:sock] handleReceivedData:data];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    //断开连接后，就从数组中删除对应socketUser对象
    //通知这也是唯一一个删除对应用户的时间点
    [_allChatUsers removeObject:[self socketUserWithAsyncSocket:sock]];
}

@end
