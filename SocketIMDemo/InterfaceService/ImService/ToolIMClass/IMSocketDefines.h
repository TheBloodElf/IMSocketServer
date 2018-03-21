//
//  IMSocketDefines.h
//  SocketIMDemo
//
//  Created by 李勇 on 18/3/15.
//  Copyright (c) 2018年李勇. All rights reserved.
//

#ifndef IMSocketControl_IMSocketDefines_h
#define IMSocketControl_IMSocketDefines_h

//包类型，放在包头部的type中
typedef enum {
    /**连接建立时的"握手"包 其实系统提供的Socket接口已经做了握手的处理，我们发这个包只是为了获取数据加密密钥 换一个角度理解就是：我们自己客户端和服务器还需要确认一次连接，服务器好准备一些数据*/
    E_SOCKET_HEADER_CMD_HANDSHAKE   = 1,
    /**公共包（发送、接收消息都是这个类型）*/
    E_SOCKET_HEADER_CMD_COMMON      = 2,
    /**维持连接的心跳包*/
    E_SOCKET_HEADER_CMD_KEEPALIVE   = 3,
    /**登录包*/
    E_SOCKET_HEADER_CMD_LOGIN       = 4,
    /**退出登录包*/
    E_SOCKET_HEADER_CMD_LOGOUT      = 5
} E_SOCKET_HEADER_CMD_TYPE;

//客户端类型
typedef enum {
    /**未知客户端类型*/
    E_SOCKET_CLIENT_TYPE_UNKNOWN        = 1,
    /**Web客户端*/
    E_SOCKET_CLIENT_TYPE_PC_WEB         = 2,
    /**Android客户端*/
    E_SOCKET_CLIENT_TYPE_PHONE_ANDROID  = 3,
    /**iOS客户端*/
    E_SOCKET_CLIENT_TYPE_PHONE_IOS      = 4
} E_SOCKET_CLIENT_TYPE;

//Socket错误码
typedef enum {
    /**成功*/
    E_SOCKET_ERROR_NONE             = 0,
    
    /**登录信息错误*/
    E_SOCKET_ERROR_LOGIN_INFO_ERROR   = 4001,
    /**用户不在线*/
    E_SOCKET_ERROR_USER_NOT_EXIST     = 4002,
} E_SOCKET_ERROR;

//服务器返回的包类型
typedef enum {
    /**请求包，服务器也可以主动向客户端发起数据请求*/
    PACK_TYPE_REQ = 1,
    /**响应包，客户端发起的请求，服务器响应则为此类型*/
    PACK_TYPE_RESP = 2,
    /**通知包，表示客户端没有发起请求，但是有消息需要直接发送给客户端*/
    PACK_TYPE_NOTIFY = 3
} E_SERVER_PACK_TYPE;

#endif

