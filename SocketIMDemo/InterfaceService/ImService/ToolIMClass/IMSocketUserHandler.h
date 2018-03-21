//
//  CMUserModule.h
//  IMSocketWatcher
//
//  Created by 李勇 on 18/3/15.
//  Copyright (c) 2018年李勇. All rights reserved.
//

/**
 客户端用户的登录请求
 */
@interface UserLoginReq : NSObject

/**用户名 为用户体系的uid字符串*/
@property (nonatomic, strong) NSString* username;
/**密码，因为服务器不做用户验证处理，所以只需要为@"bb_password"即可*/
@property (nonatomic, strong) NSString* passwd;
/**客户端版本号*/
@property (nonatomic, strong) NSString* client_version;
/**设备Token，用来向客户端发送apns推送使用*/
@property (nonatomic, strong) NSString* device_token;

@end

/**
 返回给客户端的用户登录响应
 */
@interface UserLoginResp : NSObject

/**用户在聊天体系中的唯一标识符，现在直接设置为UserLoginReq中username的long long value*/
@property (nonatomic, assign) uint64_t imid;

@end

/**
 用户被踢下线通知
 */
@interface UserKickoutNotify : NSObject

/**原因 1被T，其他原因后面慢慢发现*/
@property (nonatomic, assign) uint32_t reason;
/**哪个终端把你踢下线的*/
@property (nonatomic, assign) E_SOCKET_CLIENT_TYPE from_source_type;

@end
