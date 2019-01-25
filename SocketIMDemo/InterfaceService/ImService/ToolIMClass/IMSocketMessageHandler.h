//
//  IMSocketMessageHandler.h
//  IMServer
//
//  Created by Mac on 2018/3/27.
//  Copyright © 2018年 Mac. All rights reserved.
//

#pragma mark -- 单聊消息

/**
 单聊消息
 */
@interface MsgContent : NSObject

/**消息ID，该字段由客户端补充（我们假设所有端的时间一致），建议用毫秒时间戳既可（1970.1.1到现在的时间），主要用于发送消息的重发，和本地消息的去重 但是网上都说最好服务器填充，因为客户端可以改时间，但我们不考虑这种情况，因为我们取的是1970.1.1到现在的时间*/
@property (nonatomic, assign) int64_t msg_id;
/**发送消息时填自己的终端类型，接收消息时为对方的终端类型*/
@property (nonatomic, assign) E_SOCKET_CLIENT_TYPE from_source_type;
/**发送消息时，自己的uid，接收消息时是对方的uid*/
@property (nonatomic, assign) int64_t sender_imid;
/**发送消息时，对方的uid,接收时自己的uid*/
@property (nonatomic, assign) int64_t reciver_imid;
/**消息时间，发送消息时可以不关心这个字段，由server填充，如果是接收方，则是收到该消息的时间，单位秒*/
@property (nonatomic, assign) int64_t time;
/**消息内容 是IMChatMesssage对象的json格式字符串*/
@property (nonatomic, strong) NSString *msg_data;

@end

/**
 发送单聊消息的响应
 */
@interface MsgSendResp : NSObject

@end

/**
 收到在线消息时，需要发送ack给服务器
 */
@interface MsgAckContent : NSObject

/**消息id 直接取消息的msgid*/
@property (nonatomic, assign) int64_t ack_msgid;
/**要回执的终端，默认直接把收到消息的from_source_type填上既可*/
@property (nonatomic, assign) E_SOCKET_CLIENT_TYPE ack_source_type;
/**消息发送方的imid 直接取消息的sender_imid 可以拿来做消息"对方已读"标记，给ack_imid用户发送一条"已读"消息即可*/
@property (nonatomic, assign) int64_t ack_imid;
/**回执方自己的imid 直接取消息的reciver_imid 在群聊的时候用来判断谁读了消息，拉离线就不会再发了*/
@property (nonatomic, assign) int64_t sender_imid;

@end

/**
 收到在线消息时，需要发送ack给服务器收到的响应
 */
@interface MsgSendAckResp : NSObject

@end

/**
 收到单聊消息
 */
@interface MsgPushNotify : NSObject

/**发送发imid*/
@property (nonatomic, assign) int64_t sender_imid;
/**接收发imid*/
@property (nonatomic, assign) int64_t reciver_imid;
/**消息id*/
@property (nonatomic, assign) int64_t msg_id;
/**消息时间 服务器填  单位毫秒*/
@property (nonatomic, assign) int64_t time;
/**消息体 是IMChatMesssage对象的json格式字符串*/
@property (nonatomic, strong) NSString* msg_data;

@end
