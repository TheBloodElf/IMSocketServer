//
//  IMChatMessage.h
//  SocketIMDemo
//
//  Created by Mac on 2018/3/27.
//  Copyright © 2018年 Mac. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 服务器会把这个消息进行存储，并加上是否已读的标记（ack有没有收到）
 那么当10001获取他的未读消息时，则从数据库中获取reciver_imid=10001&&is_read=NO即可；因为并不会存在sender_imid=10001的未读消息（想一下发送逻辑）
 该类数据取自MsgContent
 */
@interface IMMsgContent : RLMObject

/**消息ID，该字段由客户端补充，建议用毫秒时间戳既可，主要用于发送消息的重发，和本地消息的去重*/
@property (nonatomic, assign) int64_t msg_id;
/**发送消息时填自己的终端类型，接收消息时为对方的终端类型*/
@property (nonatomic, assign) E_SOCKET_CLIENT_TYPE from_source_type;
/**发送消息时，自己的uid，接收消息时是对方的uid*/
@property (nonatomic, assign) int64_t sender_imid;
/**发送消息时，对方的uid,接收时自己的uid*/
@property (nonatomic, assign) int64_t reciver_imid;
/**消息时间，发送消息时可以不关心这个字段，由server填充，如果是接收方，则是收到该消息的时间，单位毫秒*/
@property (nonatomic, assign) int64_t time;
/**消息内容 是IMChatMesssage对象的json格式字符串*/
@property (nonatomic, strong) NSString *msg_data;
/**是否已读，未读则视为离线消息*/
@property (nonatomic, assign) BOOL is_read;

@end
